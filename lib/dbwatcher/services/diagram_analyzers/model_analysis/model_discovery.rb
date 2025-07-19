# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      module ModelAnalysis
        # Service responsible for discovering and filtering ActiveRecord models
        #
        # This service handles the complex logic of finding ActiveRecord models
        # that are relevant for diagram analysis, including models from gems,
        # namespaced models, and models with custom table names.
        class ModelDiscovery
          attr_reader :session_tables, :discovered_models

          # Initialize with optional session tables for filtering
          #
          # @param session_tables [Array<String>] table names from session (empty for global analysis)
          def initialize(session_tables = [])
            @session_tables = session_tables || []
            @discovered_models = []
          end

          # Discover models that correspond to session tables or all models if no session
          #
          # @return [Array<Class>] ActiveRecord model classes
          def discover
            return [] unless activerecord_available?

            begin
              all_models = load_all_models
              @discovered_models = filter_models_by_session(all_models)

              log_discovery_results
              @discovered_models
            rescue StandardError => e
              Rails.logger.error "ModelDiscovery: Error discovering models: #{e.message}"
              []
            end
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

            Rails.logger.debug "ModelDiscovery: Found #{all_models.size} total ActiveRecord models"
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
            Rails.logger.debug "ModelDiscovery: Error validating model #{model}: #{e.message}"
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

          private

          # Check if ActiveRecord is available
          #
          # @return [Boolean]
          def activerecord_available?
            defined?(ActiveRecord::Base)
          end

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
                error_message = "ModelDiscovery: Could not eager load engine #{engine.class.name}: #{e.message}"
                Rails.logger.debug error_message
              end
            rescue StandardError => e
              Rails.logger.debug "ModelDiscovery: Could not eager load models: #{e.message}"
            end
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
              Rails.logger.warn "ModelDiscovery: Error checking table_name for " \
                                "#{model.name}: #{e.message}"
            end

            # Select models whose tables are in the session
            filtered_models = []
            session_tables.each do |table_name|
              models_for_table = table_to_models[table_name]
              filtered_models.concat(models_for_table) if models_for_table
            end

            filtered_models
          end

          # Log discovery results for debugging
          #
          # @return [void]
          def log_discovery_results
            if discovered_models.any?
              model_table_info = discovered_models.map { |m| "#{m.name} (#{m.table_name})" }
              Rails.logger.debug "ModelDiscovery: Discovered models: #{model_table_info.join(", ")}"
            end

            Rails.logger.debug "ModelDiscovery: Filtered to #{discovered_models.size} " \
                               "models matching session tables (from #{session_tables.size} tables)"
          end
        end
      end
    end
  end
end