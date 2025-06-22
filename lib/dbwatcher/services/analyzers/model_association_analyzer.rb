# frozen_string_literal: true

module Dbwatcher
  module Services
    module Analyzers
      # Analyzes relationships based on ActiveRecord model associations
      #
      # This service examines ActiveRecord model classes to detect associations
      # like has_many, belongs_to, etc. between models whose tables were involved in a session.
      #
      # @example
      #   analyzer = ModelAssociationAnalyzer.new(session)
      #   associations = analyzer.call
      #   # => [{ source_model: "User", target_model: "Order", type: "has_many" }]
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

        # New standardized interface: analyze model associations
        #
        # @param context [Hash] analysis context
        # @return [Array<Hash>] array of association data
        def analyze(context)
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

        # Transform raw association data to DiagramDataset
        #
        # @param raw_data [Array<Hash>] raw association data
        # @return [DiagramData::DiagramDataset] standardized dataset
        def transform_to_dataset(raw_data)
          dataset = create_empty_dataset
          dataset.metadata.merge!({
                                    analyzer_type: "model_associations",
                                    total_associations: raw_data.length,
                                    models_analyzed: models.length
                                  })

          # Create entities for each unique model
          model_entities = {}
          raw_data.each do |association|
            # Create source entity
            if association[:source_model] && !model_entities.key?(association[:source_model])
              entity = create_entity(
                id: association[:source_table] || association[:source_model].downcase,
                name: association[:source_model],
                type: "model",
                metadata: {
                  table_name: association[:source_table],
                  model_class: association[:source_model]
                }
              )
              dataset.add_entity(entity)
              model_entities[association[:source_model]] = entity
            end

            # Create target entity (if exists)
            next unless association[:target_model] && !model_entities.key?(association[:target_model])

            entity = create_entity(
              id: association[:target_table] || association[:target_model].downcase,
              name: association[:target_model],
              type: "model",
              metadata: {
                table_name: association[:target_table],
                model_class: association[:target_model]
              }
            )
            dataset.add_entity(entity)
            model_entities[association[:target_model]] = entity
          end

          # Create relationships
          raw_data.each do |association|
            next if association[:type] == "node_only" || !association[:target_model]

            source_id = association[:source_table] || association[:source_model].downcase
            target_id = association[:target_table] || association[:target_model].downcase

            # Skip self-referential relationships (source and target are the same)
            if source_id == target_id
              Rails.logger.info "ModelAssociationAnalyzer: Skipping self-referential relationship for #{source_id}"
              next
            end

            relationship = create_relationship(
              source_id: source_id,
              target_id: target_id,
              type: association[:type],
              label: association[:association_name],
              metadata: {
                association_name: association[:association_name],
                source_model: association[:source_model],
                target_model: association[:target_model],
                original_type: association[:type]
              }
            )

            dataset.add_relationship(relationship)
          end

          dataset
        end

        # Analyzer capabilities
        #
        # @return [Array<Symbol>] capabilities
        def capabilities
          %i[model_associations activerecord_models table_relationships]
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
            # Try common model naming conventions
            model_candidates = [
              table_name.singularize.camelize,           # users -> User
              table_name.classify,                       # user_profiles -> UserProfile
              table_name.singularize.camelize.pluralize  # people -> People
            ].uniq

            model_candidates.each do |model_name|
              model_class = model_name.constantize
              if model_class < ActiveRecord::Base && model_has_table?(model_class)
                models << model_class
                Rails.logger.debug "ModelAssociationAnalyzer: Successfully loaded model " \
                                   "#{model_name} for table #{table_name}"
                break # Found a valid model for this table
              end
            rescue NameError
              # Model doesn't exist, try next candidate
              Rails.logger.debug "ModelAssociationAnalyzer: Model #{model_name} not found for table #{table_name}"
            rescue StandardError => e
              Rails.logger.debug "ModelAssociationAnalyzer: Error loading model #{model_name}: #{e.message}"
            end
          end

          models.uniq
        end

        # Check if model has a valid table
        #
        # @param model [Class] ActiveRecord model class
        # @return [Boolean] true if model has table
        def model_has_table?(model)
          model.table_exists?
        rescue StandardError => e
          Rails.logger.debug "ModelAssociationAnalyzer: Model #{model.name} has no table: #{e.message}"
          false
        end

        # Extract all associations from discovered models
        #
        # @return [Array<Hash>] associations array
        def extract_model_associations
          associations = []

          begin
            Rails.logger.debug "ModelAssociationAnalyzer: Starting extraction from #{models.length} models"

            models.each do |model|
              Rails.logger.debug "ModelAssociationAnalyzer: Processing model: #{model.name}"
              model_associations = get_model_associations(model)

              Rails.logger.debug "ModelAssociationAnalyzer: Found #{model_associations.size} " \
                                 "associations for #{model.name}"

              model_associations.each do |association|
                # Only include associations where target is also in scope
                if target_model_in_scope?(association)
                  relationship = build_association_relationship(model, association)
                  associations << relationship if relationship
                end
              rescue StandardError => e
                Rails.logger.warn "ModelAssociationAnalyzer: Error processing association " \
                                  "in #{model.name}: #{e.message}"
                # Continue with next association
              end
            rescue StandardError => e
              Rails.logger.warn "ModelAssociationAnalyzer: Error processing model #{model.name}: #{e.message}"
              # Continue with next model
            end

            Rails.logger.debug "ModelAssociationAnalyzer: Extracted #{associations.compact.length} valid associations"
          rescue StandardError => e
            Rails.logger.error "ModelAssociationAnalyzer: Error in extraction process: #{e.message}"
          end

          associations.compact
        end

        # Get associations for a model
        #
        # @param model [Class] ActiveRecord model class
        # @return [Array] association reflection objects
        def get_model_associations(model)
          model.reflect_on_all_associations
        rescue StandardError => e
          Rails.logger.warn "ModelAssociationAnalyzer: Error getting associations for #{model.name}: #{e.message}"
          []
        end

        # Check if target model is in analysis scope
        #
        # @param association [Object] association reflection
        # @return [Boolean] true if target should be included
        def target_model_in_scope?(association)
          target_table = association.table_name
          # If analyzing session, target table must be in session
          # If analyzing globally, include all
          session_tables.empty? || session_tables.include?(target_table)
        rescue StandardError => e
          Rails.logger.debug "ModelAssociationAnalyzer: Error checking target scope for association: #{e.message}"
          false
        end

        # Build association relationship data
        #
        # @param model [Class] source model class
        # @param association [Object] association reflection
        # @return [Hash, nil] association data or nil
        def build_association_relationship(model, association)
          case association.macro
          when :belongs_to
            build_belongs_to_relationship(model, association)
          when :has_one
            build_has_one_relationship(model, association)
          when :has_many
            if association.through_reflection
              build_has_many_through_relationship(model, association)
            else
              build_has_many_relationship(model, association)
            end
          when :has_and_belongs_to_many
            build_habtm_relationship(model, association)
          when :has_one_attached, :has_many_attached
            build_active_storage_relationship(model, association)
          end
        rescue StandardError => e
          message = "ModelAssociationAnalyzer: Error building relationship for " \
                    "#{model.name}##{association.name}: #{e.message}"
          Rails.logger.warn message
          nil
        end

        # Build belongs_to relationship data
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_belongs_to_relationship(model, association)
          {
            type: "belongs_to",
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            foreign_key: association.foreign_key,
            primary_key: association.active_record_primary_key,
            association_name: association.name.to_s,
            optional: association.options[:optional] || false,
            polymorphic: association.polymorphic? || false
          }
        end

        # Build has_one relationship data
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_has_one_relationship(model, association)
          {
            type: "has_one",
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            foreign_key: association.foreign_key,
            primary_key: association.active_record_primary_key,
            association_name: association.name.to_s,
            dependent: association.options[:dependent]
          }
        end

        # Build has_many relationship data
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_has_many_relationship(model, association)
          {
            type: "has_many",
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            foreign_key: association.foreign_key,
            primary_key: association.active_record_primary_key,
            association_name: association.name.to_s,
            dependent: association.options[:dependent]
          }
        end

        # Build has_many through relationship data
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_has_many_through_relationship(model, association)
          {
            type: "has_many_through",
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            through_model: association.through_reflection.class_name,
            through_table: get_association_table_name(association.through_reflection),
            source_association: association.source_reflection&.name&.to_s,
            association_name: association.name.to_s
          }
        end

        # Build HABTM relationship data
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_habtm_relationship(model, association)
          {
            type: "has_and_belongs_to_many",
            source_model: model.name,
            source_table: model.table_name,
            target_model: association.class_name,
            target_table: get_association_table_name(association),
            join_table: association.join_table,
            foreign_key: association.foreign_key,
            association_foreign_key: association.association_foreign_key,
            association_name: association.name.to_s
          }
        end

        # Build Active Storage relationship data
        #
        # @param model [Class] source model
        # @param association [Object] association reflection
        # @return [Hash] relationship data
        def build_active_storage_relationship(model, association)
          {
            type: association.macro.to_s,
            source_model: model.name,
            source_table: model.table_name,
            target_model: "ActiveStorage::Attachment",
            target_table: "active_storage_attachments",
            association_name: association.name.to_s,
            service: "active_storage"
          }
        end

        # Get table name for association safely
        #
        # @param association [Object] association reflection
        # @return [String] table name
        def get_association_table_name(association)
          association.table_name
        rescue StandardError
          "unknown_table"
        end

        # Build context for logging
        #
        # @return [Hash] analysis context
        def analysis_context
          {
            session_id: session&.id,
            session_tables_count: session_tables.length,
            models_found: models.length,
            analyzing_scope: session_tables.any? ? "session" : "global"
          }
        end

        private

        # Implement required abstract methods from BaseAnalyzer

        # Get analyzer name
        #
        # @return [String] analyzer name
        def analyzer_name
          "Model Association Analyzer"
        end

        # Get analyzer description
        #
        # @return [String] analyzer description
        def analyzer_description
          "Analyzes ActiveRecord model associations to detect relationships between models"
        end
      end
    end
  end
end
