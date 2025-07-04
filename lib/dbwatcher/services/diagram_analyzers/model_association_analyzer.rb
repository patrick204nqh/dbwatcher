# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Analyzes relationships based on ActiveRecord model associations
      #
      # This service examines ActiveRecord models to detect associations between
      # models that were involved in a session.
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
          @models = discover_session_models
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

          # Add placeholder nodes for models without associations
          associations = generate_placeholder_associations if associations.empty? && models.any?

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

          associations
        end

        # Transform raw association data to Dataset
        #
        # @param raw_data [Array<Hash>] raw association data
        # @return [DiagramData::Dataset] standardized dataset
        def transform_to_dataset(raw_data)
          dataset = create_empty_dataset
          dataset.metadata.merge!({
                                    total_relationships: raw_data.count { |a| a[:target_model] },
                                    total_models: models.length,
                                    model_names: models.map(&:name)
                                  })

          # Create entities for each unique model
          model_entities = {}

          # First, collect all unique models from the associations
          models_to_process = []
          raw_data.each do |association|
            models_to_process << association[:source_model] if association[:source_model]
            models_to_process << association[:target_model] if association[:target_model]
          end
          models_to_process.uniq!

          # Create entities for all models
          models_to_process.each do |model_name|
            # Find the model class to extract attributes
            model_class = find_model_class(model_name)
            attributes = extract_model_attributes(model_class)
            methods = extract_model_methods(model_class)

            # Get table name if available
            table_name = model_class.respond_to?(:table_name) ? model_class.table_name : model_name.downcase

            entity = create_entity(
              id: table_name || model_name.downcase,
              name: model_name,
              type: "model",
              attributes: attributes,
              metadata: {
                table_name: table_name,
                model_class: model_name,
                methods: methods
              }
            )
            dataset.add_entity(entity)
            model_entities[model_name] = entity
          end

          # Create relationships in a separate loop
          raw_data.each do |association|
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
              # Model doesn't exist, try the next one
              next
            end
          end

          models
        end

        # Check if model has a database table
        #
        # @param model [Class] ActiveRecord model class
        # @return [Boolean] true if model has a table
        def model_has_table?(model)
          model.table_exists?
        rescue StandardError
          false
        end

        # Extract associations from all models
        #
        # @return [Array<Hash>] associations array
        def extract_model_associations
          associations = []

          models.each do |model|
            model_associations = get_model_associations(model)

            model_associations.each do |association|
              # Skip polymorphic associations for now
              next if association.options[:polymorphic]

              # Skip if target model is not in scope
              next unless target_model_in_scope?(association)

              # Build relationship based on association type
              relationship = build_association_relationship(model, association)
              associations << relationship if relationship
            end
          end

          associations
        end

        # Get associations for a model
        #
        # @param model [Class] ActiveRecord model class
        # @return [Array] association objects
        def get_model_associations(model)
          model.reflect_on_all_associations
        rescue StandardError => e
          Rails.logger.warn "ModelAssociationAnalyzer: Could not get associations for #{model.name}: #{e.message}"
          []
        end

        # Check if target model is in analysis scope
        #
        # @param association [Object] association object
        # @return [Boolean] true if target model should be included
        def target_model_in_scope?(association)
          target_table = get_association_table_name(association)

          # If analyzing session, both tables must be in session
          # If analyzing globally, include all
          return true if session_tables.empty?

          # Skip if target table is not in session
          return false if target_table && !session_tables.include?(target_table)

          true
        end

        # Build relationship hash based on association type
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
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
          else
            # Handle special cases like has_one_attached from Active Storage
            if association.name.to_s.end_with?("_attachment") || association.name.to_s.end_with?("_attachments")
              build_active_storage_relationship(model, association)
            else
              Rails.logger.warn "ModelAssociationAnalyzer: Unknown association type: " \
                                "#{association.macro} for #{model.name}.#{association.name}"
              nil
            end
          end
        end

        # Build belongs_to relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
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
        # @param model [Class] source model class
        # @param association [Object] association object
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
        # @param model [Class] source model class
        # @param association [Object] association object
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
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_has_many_through_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: "has_many_through",
            association_name: "#{association.name} (through #{association.options[:through]})"
          }
        end

        # Build has_and_belongs_to_many relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
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
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_active_storage_relationship(model, association)
          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: "ActiveStorage::Attachment",
            target_table: "active_storage_attachments",
            type: "has_one",
            association_name: association.name.to_s
          }
        end

        # Get table name for association target
        #
        # @param association [Object] association object
        # @return [String, nil] table name
        def get_association_table_name(association)
          association.table_name
        rescue StandardError => e
          Rails.logger.warn "ModelAssociationAnalyzer: Could not get table name for #{association.name}: #{e.message}"
          nil
        end

        # Find model class by name
        #
        # @param model_name [String] model class name
        # @return [Class, nil] model class
        def find_model_class(model_name)
          model_name.constantize
        rescue StandardError => e
          Rails.logger.warn "ModelAssociationAnalyzer: Could not find model class #{model_name}: #{e.message}"
          nil
        end

        # Extract attributes from model class
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
                  visibility: "+" # Public visibility for all columns
                }
              )
            end
          rescue StandardError => e
            Rails.logger.warn "ModelAssociationAnalyzer: Could not extract attributes for " \
                              "#{model_class.name}: #{e.message}"
            []
          end
        end

        # Extract methods from model class
        #
        # @param model_class [Class, nil] ActiveRecord model class
        # @return [Array<Hash>] model methods
        def extract_model_methods(model_class)
          return [] unless model_class && Dbwatcher.configuration.diagram_show_methods

          methods = []

          begin
            # Get instance methods defined in the model (not inherited from ActiveRecord::Base)
            model_methods = model_class.instance_methods - ActiveRecord::Base.instance_methods
            model_methods.each do |method_name|
              # Skip association methods and attribute methods
              next if method_name.to_s.end_with?("=") || model_class.column_names.include?(method_name.to_s)

              methods << {
                name: method_name.to_s,
                visibility: "+" # Public visibility for all methods
              }
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
        # @return [String, nil] cardinality type
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
