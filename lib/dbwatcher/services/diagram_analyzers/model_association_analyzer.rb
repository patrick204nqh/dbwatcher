# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Analyzes relationships based on ActiveRecord model associations
      #
      # This service examines ActiveRecord models to detect associations between
      # models that were involved in a session. It uses direct model enumeration
      # from ActiveRecord::Base.descendants to ensure reliable model discovery.
      #
      # Supported model scenarios:
      # - Regular models with standard table names
      # - Namespaced models (e.g., Admin::User)
      # - Models with custom table names (using self.table_name)
      # - Models from external gems and complex inheritance hierarchies
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
          associations = generate_placeholder_associations if associations.empty? && models.any?

          log_analysis_results(associations)
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

          # Create entities from actual discovered models (no inference)
          create_entities_from_models(dataset)

          # Create relationships from association data
          create_relationships_from_associations(dataset, raw_data)

          dataset
        end

        # Create entities from discovered model classes
        #
        # @param dataset [DiagramData::Dataset] dataset to add entities to
        # @return [void]
        def create_entities_from_models(dataset)
          models.each do |model_class|
            attributes = extract_model_attributes(model_class)
            methods = extract_model_methods(model_class)

            entity = create_entity(
              id: model_class.table_name,
              name: model_class.name,
              type: "model",
              attributes: attributes,
              metadata: {
                table_name: model_class.table_name,
                model_class: model_class.name,
                methods: methods
              }
            )
            dataset.add_entity(entity)
          end
        end

        # Create relationships from association data
        #
        # @param dataset [DiagramData::Dataset] dataset to add relationships to
        # @param raw_data [Array<Hash>] raw association data
        # @return [void]
        def create_relationships_from_associations(dataset, raw_data)
          raw_data.each do |association|
            next if association[:type] == "node_only" || !association[:target_model]

            source_id = association[:source_table]
            target_id = association[:target_table]

            # Skip if we don't have valid table IDs
            next unless source_id && target_id

            # Determine cardinality based on relationship type
            cardinality = determine_cardinality(association[:type])

            relationship = create_relationship({
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
                                               })

            dataset.add_relationship(relationship)
          end
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

        # Eagerly load all models including those from gems
        #
        # @return [void]
        def eager_load_models
          return unless defined?(Rails) && Rails.respond_to?(:application)

          begin
            # Force eager loading of application models
            Rails.application.eager_load!

            # Also load models from engines/gems if any are configured
            Rails::Engine.descendants.each do |engine|
              engine.eager_load! if engine.respond_to?(:eager_load!)
            rescue StandardError => e
              error_message = "ModelAssociationAnalyzer: Could not eager load engine #{engine.class.name}: #{e.message}"
              Rails.logger.debug error_message
            end
          rescue StandardError => e
            Rails.logger.debug "ModelAssociationAnalyzer: Could not eager load models: #{e.message}"
          end
        end

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
          unless activerecord_available?
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
          return [] unless activerecord_available?

          begin
            all_models = load_all_models
            discovered_models = filter_models_by_session(all_models)

            # Log the discovered models and their table names for debugging
            if discovered_models.any?
              model_table_info = discovered_models.map { |m| "#{m.name} (#{m.table_name})" }
              Rails.logger.debug "ModelAssociationAnalyzer: Discovered models: #{model_table_info.join(", ")}"
            end

            discovered_models
          rescue StandardError => e
            Rails.logger.error "ModelAssociationAnalyzer: Error discovering models: #{e.message}"
            []
          end
        end

        # Log analysis results for debugging
        #
        # @param associations [Array<Hash>] found associations
        # @return [void]
        def log_analysis_results(associations)
          Rails.logger.debug "ModelAssociationAnalyzer: Found #{associations.length} associations"

          if associations.any?
            sample_association = associations.first
            Rails.logger.debug "ModelAssociationAnalyzer: Sample association - " \
                               "source_model: #{sample_association[:source_model]}, " \
                               "target_model: #{sample_association[:target_model]}, " \
                               "type: #{sample_association[:type]}"
          else
            Rails.logger.info "ModelAssociationAnalyzer: No associations found"
          end
        end

        # === Model Discovery Methods ===

        # Check if ActiveRecord is available
        #
        # @return [Boolean]
        def activerecord_available?
          defined?(ActiveRecord::Base)
        end

        # Load all available ActiveRecord models including from gems
        #
        # @return [Array<Class>] ActiveRecord model classes
        def load_all_models
          eager_load_models

          # Get all model classes directly from ActiveRecord descendants
          all_models = ActiveRecord::Base.descendants
                                         .select { |model| valid_model_class?(model) }
                                         .uniq

          Rails.logger.debug "ModelAssociationAnalyzer: Found #{all_models.size} total ActiveRecord models"
          all_models
        end

        # Check if a model class is valid for analysis
        #
        # @param model [Class] ActiveRecord model class
        # @return [Boolean] true if model is valid
        def valid_model_class?(model)
          # Must be a proper class with a name (not anonymous)
          return false unless model.name

          # Must have a table that exists
          return false unless model_has_table?(model)

          # Skip abstract models
          return false if model.abstract_class?

          true
        rescue StandardError => e
          Rails.logger.debug "ModelAssociationAnalyzer: Error validating model #{model}: #{e.message}"
          false
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

        # Filter models based on session tables
        #
        # @param all_models [Array<Class>] all available models
        # @return [Array<Class>] filtered models
        def filter_models_by_session(all_models)
          return all_models if session_tables.empty?

          # Build a hash of table_name -> model for efficient lookup
          table_to_models = {}
          all_models.each do |model|
            table_name = model.table_name
            table_to_models[table_name] ||= []
            table_to_models[table_name] << model
          rescue StandardError => e
            Rails.logger.warn "ModelAssociationAnalyzer: Error checking table_name for " \
                              "#{model.name}: #{e.message}"
          end

          # Select models whose tables are in the session
          filtered_models = []
          session_tables.each do |table_name|
            models_for_table = table_to_models[table_name]
            filtered_models.concat(models_for_table) if models_for_table
          end

          Rails.logger.debug "ModelAssociationAnalyzer: Filtered to #{filtered_models.size} " \
                             "models matching session tables (from #{session_tables.size} tables)"
          filtered_models
        end

        # === Association Analysis Methods ===

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

        # Build a standardized relationship hash
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @param type [String] relationship type
        # @return [Hash] relationship data
        def build_relationship_hash(model, association, type)
          return nil unless association&.class_name

          {
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            type: type,
            association_name: association.name.to_s
          }
        end

        # Build belongs_to relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_belongs_to_relationship(model, association)
          build_relationship_hash(model, association, "belongs_to")
        end

        # Build has_one relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_has_one_relationship(model, association)
          build_relationship_hash(model, association, "has_one")
        end

        # Build has_many relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_has_many_relationship(model, association)
          build_relationship_hash(model, association, "has_many")
        end

        # Build has_many :through relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_has_many_through_relationship(model, association)
          relationship = build_relationship_hash(model, association, "has_many_through")
          relationship[:association_name] = "#{association.name} (through #{association.options[:through]})"
          relationship
        end

        # Build has_and_belongs_to_many relationship
        #
        # @param model [Class] source model class
        # @param association [Object] association object
        # @return [Hash] relationship data
        def build_habtm_relationship(model, association)
          build_relationship_hash(model, association, "has_and_belongs_to_many")
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
