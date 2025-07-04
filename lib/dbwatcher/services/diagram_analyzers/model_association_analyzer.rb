# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Analyzes relationships based on ActiveRecord model associations
      #
      # This service examines ActiveRecord model classes to detect associations
      # like has_many, belongs_to, etc. between models whose tables were involved in a session.
      #
      # @example
      #   analyzer = ModelAssociationAnalyzer.new(session)
      #   dataset = analyzer.call
      class ModelAssociationAnalyzer < BaseAnalyzer
        # Initialize with session
        #
        # @param session [Session] session to analyze (optional for global analysis)
        def initialize(session = nil)
          @session = session
          @session_tables = session ? extract_session_tables : []

          # Log session tables for debugging
          if @session_tables.any?
            table_list = @session_tables.join(", ")
            Rails.logger.info "ModelAssociationAnalyzer: Found #{@session_tables.size} tables " \
                              "in session: #{table_list}"
          else
            Rails.logger.warn "ModelAssociationAnalyzer: No tables found in session"
          end

          @models = discover_session_models

          # Log discovered models for debugging
          if @models.any?
            model_names = @models.map(&:name).join(", ")
            Rails.logger.info "ModelAssociationAnalyzer: Discovered #{@models.size} models: #{model_names}"
          else
            Rails.logger.warn "ModelAssociationAnalyzer: No models discovered for session tables"
          end

          super()
        end

        # Analyze model associations
        #
        # @param context [Hash] analysis context
        # @return [Array<Hash>] array of association data
        def analyze(_context)
          return [] unless models_available?

          Rails.logger.debug "ModelAssociationAnalyzer: Starting analysis with #{models.length} models"
          associations = extract_model_associations

          # Log some sample data to help with debugging
          if associations.any?
            sample_association = associations.first
            Rails.logger.debug "ModelAssociationAnalyzer: Sample association - " \
                               "source_model: #{sample_association[:source_model]}, " \
                               "target_model: #{sample_association[:target_model]}, " \
                               "type: #{sample_association[:type]}"
          else
            Rails.logger.info "ModelAssociationAnalyzer: No associations found"
          end

          # If no associations found but we have models, generate a placeholder
          if associations.empty? && models.any?
            Rails.logger.info "ModelAssociationAnalyzer: Creating placeholder associations " \
                              "for #{models.length} models"
            associations = generate_placeholder_associations
          end

          associations
        end

        # Transform raw association data to Dataset
        #
        # @param raw_data [Array<Hash>] raw association data
        # @return [DiagramData::Dataset] standardized dataset
        def transform_to_dataset(raw_data)
          dataset = create_empty_dataset
          dataset.metadata.merge!({
                                    total_associations: raw_data.length,
                                    models_analyzed: models.length
                                  })

          # Create entities for each unique model
          model_entities = {}
          raw_data.each do |association|
            # Create source entity
            if association[:source_model] && !model_entities.key?(association[:source_model])
              # Find the model class to extract attributes
              source_model_class = find_model_class(association[:source_model])
              attributes = extract_model_attributes(source_model_class)
              methods = extract_model_methods(source_model_class)

              entity = create_entity(
                id: association[:source_table] || association[:source_model].downcase,
                name: association[:source_model],
                type: "model",
                attributes: attributes,
                metadata: {
                  table_name: association[:source_table],
                  model_class: association[:source_model],
                  methods: methods
                }
              )
              dataset.add_entity(entity)
              model_entities[association[:source_model]] = entity
            end

            # Create target entity (if exists)
            next unless association[:target_model] && !model_entities.key?(association[:target_model])

            # Find the model class to extract attributes
            target_model_class = find_model_class(association[:target_model])
            attributes = extract_model_attributes(target_model_class)
            methods = extract_model_methods(target_model_class)

            entity = create_entity(
              id: association[:target_table] || association[:target_model].downcase,
              name: association[:target_model],
              type: "model",
              attributes: attributes,
              metadata: {
                table_name: association[:target_table],
                model_class: association[:target_model],
                methods: methods
              }
            )
            dataset.add_entity(entity)
            model_entities[association[:target_model]] = entity

            # Create relationships (separate from entity creation)
            next if association[:type] == "node_only" || !association[:target_model]

            source_id = association[:source_table] || association[:source_model].downcase
            target_id = association[:target_table] || association[:target_model].downcase

            # Include self-referential relationships (source and target are the same)
            # but log them for debugging
            if source_id == target_id
              Rails.logger.info "ModelAssociationAnalyzer: Including self-referential relationship for " \
                                "#{source_id} (#{association[:association_name]})"
            end

            # Determine cardinality based on relationship type
            cardinality = determine_cardinality(association[:type])

            relationship = create_relationship(
              source_id: source_id,
              target_id: target_id,
              type: association[:type],
              label: association[:association_name],
              cardinality: cardinality,
              metadata: {
                association_name: association[:association_name],
                source_model: association[:source_model],
                target_model: association[:target_model],
                original_type: association[:type],
                self_referential: source_id == target_id
              }
            )

            dataset.add_relationship(relationship)
          end

          dataset
        end

        # Get analyzer type
        #
        # @return [String] analyzer type identifier
        def analyzer_type
          "model_association"
        end

        protected

        # Build analysis context for this analyzer
        #
        # @return [Hash] analysis context
        def analysis_context
          {
            session: session,
            session_tables: session_tables,
            models: models
          }
        end

        private

        attr_reader :session, :session_tables, :models

        # Generate placeholder associations for models without associations
        #
        # @return [Array<Hash>] placeholder associations
        def generate_placeholder_associations
          # Create nodes for each model
          result = models.map do |model|
            {
              type: "node_only",
              source_model: model.name,
              source_table: model.table_name,
              target_model: nil,
              target_table: nil,
              association_name: nil
            }
          end

          Rails.logger.info "ModelAssociationAnalyzer: Generated #{result.size} placeholder nodes"
          result
        end

        # Check if model analysis is available
        #
        # @return [Boolean] true if models can be analyzed
        def models_available?
          unless defined?(ActiveRecord::Base)
            Rails.logger.warn "ModelAssociationAnalyzer: ActiveRecord not available"
            return false
          end

          if models.empty?
            Rails.logger.warn "ModelAssociationAnalyzer: No models available for analysis"
            return false
          end

          true
        end

        # Extract tables that were involved in the session
        #
        # @return [Array<String>] unique table names
        def extract_session_tables
          return [] unless session&.changes

          session.changes.map do |change|
            change[:table_name] || change["table_name"]
          end.compact.uniq
        end

        # Discover models that correspond to session tables
        #
        # @return [Array<Class>] ActiveRecord model classes
        def discover_session_models
          return [] unless defined?(ActiveRecord::Base)

          # Get all ActiveRecord models
          begin
            all_models = ActiveRecord::Base.descendants.select do |model|
              model_has_table?(model)
            end

            # If no models found (e.g., in test environment), try to load them explicitly
            if all_models.empty? && session_tables.any?
              Rails.logger.debug "ModelAssociationAnalyzer: No models found via descendants, " \
                                 "attempting explicit loading"
              all_models = attempt_explicit_model_loading
            end

            Rails.logger.debug "ModelAssociationAnalyzer: Found #{all_models.size} total ActiveRecord models"

            # Filter to models whose tables are in session (if session provided)
            if session_tables.any?
              filtered_models = all_models.select { |model| session_tables.include?(model.table_name) }
              Rails.logger.debug "ModelAssociationAnalyzer: Filtered to #{filtered_models.size} " \
                                 "models matching session tables"
              filtered_models
            else
              all_models
            end
          rescue StandardError => e
            Rails.logger.error "ModelAssociationAnalyzer: Error discovering models: #{e.message}"
            []
          end
        end

        # Attempt to explicitly load models based on table names
        #
        # @return [Array<Class>] ActiveRecord model classes
        def attempt_explicit_model_loading
          models = []

          session_tables.each do |table_name|
            # Try to infer model name from table name
            model_names = [
              table_name.classify,
              table_name.singularize.classify,
              table_name.pluralize.classify
            ].uniq

            model_names.each do |model_name|
              model_class = model_name.constantize
              if model_class.respond_to?(:table_name) && model_class.table_name == table_name
                models << model_class
                Rails.logger.debug "ModelAssociationAnalyzer: Loaded model #{model_name} for table #{table_name}"
                break
              end
            rescue NameError
              # Model doesn't exist, continue
            end
          end

          models
        end

        # Check if model has a corresponding table
        #
        # @param model [Class] ActiveRecord model class
        # @return [Boolean] true if model has table
        def model_has_table?(model)
          model.table_exists?
        rescue StandardError
          false
        end

        # Extract model associations
        #
        # @return [Array<Hash>] associations array
        def extract_model_associations
          associations = []

          models.each do |model|
            model_associations = get_model_associations(model)

            model_associations.each do |association|
              # Only include if target model is also in scope
              next unless target_model_in_scope?(association)

              association_data = build_association_relationship(model, association)
              associations << association_data if association_data
            end
          end

          associations
        end

        # Get associations for a model
        #
        # @param model [Class] ActiveRecord model class
        # @return [Array] association reflections
        def get_model_associations(model)
          model.reflect_on_all_associations
        rescue StandardError => e
          Rails.logger.warn "ModelAssociationAnalyzer: Could not get associations for #{model.name}: #{e.message}"
          []
        end

        # Check if target model is in analysis scope
        #
        # @param association [Object] association reflection
        # @return [Boolean] true if target model should be included
        def target_model_in_scope?(association)
          target_table = get_association_table_name(association)

          # If analyzing session, target table must be in session
          # If analyzing globally, include all
          session_tables.empty? || session_tables.include?(target_table)
        end

        # Build association relationship hash
        #
        # @param model [Class] source model class
        # @param association [Object] association reflection
        # @return [Hash, nil] association data
        def build_association_relationship(model, association)
          case association.macro
          when :belongs_to
            build_belongs_to_relationship(model, association)
          when :has_one
            build_has_one_relationship(model, association)
          when :has_many
            if association.options[:through]
              build_has_many_through_relationship(model, association)
            else
              build_has_many_relationship(model, association)
            end
          when :has_and_belongs_to_many
            build_habtm_relationship(model, association)
          when :has_one_attached, :has_many_attached
            build_active_storage_relationship(model, association)
          else
            Rails.logger.debug "ModelAssociationAnalyzer: Unknown association type #{association.macro} " \
                               "for #{model.name}##{association.name}"
            nil
          end
        end

        # Build belongs_to relationship
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_belongs_to_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: "belongs_to",
            association_name: association.name.to_s
          }
        end

        # Build has_one relationship
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_has_one_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: "has_one",
            association_name: association.name.to_s
          }
        end

        # Build has_many relationship
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_has_many_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: "has_many",
            association_name: association.name.to_s
          }
        end

        # Build has_many :through relationship
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_has_many_through_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: "has_many_through",
            association_name: association.name.to_s
          }
        end

        # Build has_and_belongs_to_many relationship
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_habtm_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: "has_and_belongs_to_many",
            association_name: association.name.to_s
          }
        end

        # Build Active Storage relationship
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_active_storage_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: "ActiveStorage::Attachment",
            target_table: "active_storage_attachments",
            type: association.macro.to_s,
            association_name: association.name.to_s
          }
        end

        # Get table name for association
        #
        # @param association [Object] association reflection
        # @return [String] table name
        def get_association_table_name(association)
          association.table_name
        rescue StandardError
          association.class_name.tableize
        end

        # Find model class by name
        #
        # @param model_name [String] model class name
        # @return [Class, nil] ActiveRecord model class or nil if not found
        def find_model_class(model_name)
          model_name.constantize
        rescue NameError
          Rails.logger.warn "ModelAssociationAnalyzer: Could not find model class #{model_name}"
          nil
        end

        # Extract attributes from model
        #
        # @param model_class [Class, nil] ActiveRecord model class
        # @return [Array<Attribute>] model attributes
        def extract_model_attributes(model_class)
          return [] unless model_class.respond_to?(:columns)

          begin
            model_class.columns.map do |column|
              create_attribute(
                name: column.name,
                type: column.type.to_s,
                nullable: column.null,
                default: column.default,
                metadata: {
                  primary_key: column.name == model_class.primary_key,
                  foreign_key: column.name.end_with?("_id"),
                  visibility: "+"
                }
              )
            end
          rescue StandardError => e
            Rails.logger.warn "ModelAssociationAnalyzer: Could not extract attributes for " \
                              "#{model_class.name}: #{e.message}"
            []
          end
        end

        # Extract methods from model
        #
        # @param model_class [Class, nil] ActiveRecord model class
        # @return [Array<Hash>] model methods
        def extract_model_methods(model_class)
          return [] unless model_class && Dbwatcher.configuration.diagram_show_methods

          methods = []

          begin
            # Add association methods
            if model_class.respond_to?(:reflect_on_all_associations)
              model_class.reflect_on_all_associations.each do |association|
                methods << {
                  name: "#{association.name}()",
                  type: "association",
                  association_type: association.macro.to_s,
                  visibility: "+"
                }
              end
            end
          rescue StandardError => e
            Rails.logger.warn "ModelAssociationAnalyzer: Could not extract methods for " \
                              "#{model_class.name}: #{e.message}"
          end

          methods
        end

        # Determine cardinality based on relationship type
        #
        # @param relationship_type [String] relationship type
        # @return [String] cardinality type
        def determine_cardinality(relationship_type)
          case relationship_type
          when "has_many"
            "one_to_many"
          when "belongs_to"
            "many_to_one"
          when "has_one"
            "one_to_one"
          when "has_and_belongs_to_many", "has_many_through"
            "many_to_many"
          end
        end
      end
    end
  end
end
