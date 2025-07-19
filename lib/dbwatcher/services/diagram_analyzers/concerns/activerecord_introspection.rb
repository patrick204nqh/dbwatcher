# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      module Concerns
        # Concern for ActiveRecord introspection utilities
        #
        # This module provides common methods for checking ActiveRecord availability
        # and performing model introspection operations.
        module ActiverecordIntrospection
          extend ActiveSupport::Concern if defined?(ActiveSupport)

          private

          # Check if ActiveRecord is available
          #
          # @return [Boolean]
          def activerecord_available?
            defined?(ActiveRecord::Base)
          end

          # Check if models analysis is available
          #
          # @return [Boolean] true if models can be analyzed
          def models_available?
            unless activerecord_available?
              Rails.logger.warn "#{self.class.name}: ActiveRecord not available"
              return false
            end

            true
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
                error_message = "#{self.class.name}: Could not eager load engine #{engine.class.name}: #{e.message}"
                Rails.logger.debug error_message
              end
            rescue StandardError => e
              Rails.logger.debug "#{self.class.name}: Could not eager load models: #{e.message}"
            end
          end
        end
      end
    end
  end
end
