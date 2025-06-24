# frozen_string_literal: true

module Dbwatcher
  module Services
    module Api
      # Service for handling diagram generation and data
      #
      # Provides diagram data for the sessions diagrams view and API endpoints
      # with caching, type validation, and comprehensive error handling.
      class DiagramDataService < BaseApiService
        VALID_DIAGRAM_TYPES = %w[database_tables model_associations].freeze
        DEFAULT_DIAGRAM_TYPE = "database_tables"

        attr_reader :diagram_type

        def initialize(session, diagram_type = nil, params = {})
          super(session, params)
          @diagram_type = normalize_diagram_type(diagram_type)
        end

        def call
          start_time = Time.now
          log_service_start("Generating #{diagram_type} diagram for session #{session.id}")

          validation_error = validate_session
          return validation_error if validation_error

          type_validation_error = validate_diagram_type
          return type_validation_error if type_validation_error

          begin
            result = with_cache(diagram_type, expires_in: cache_duration) do
              generate_diagram_data
            end

            log_service_completion(start_time, session_id: session.id, diagram_type: diagram_type)
            result
          rescue StandardError => e
            handle_error(e)
          end
        end

        # Get available diagram types
        #
        # @return [Array<String>] available diagram types
        def self.available_types
          VALID_DIAGRAM_TYPES
        end

        private

        def generate_diagram_data
          log_service_start("Generating fresh #{diagram_type} diagram")

          result = Storage.sessions.diagram_data(session.id, diagram_type)

          if result[:error]
            log_error "Diagram generation failed: #{result[:error]}"
            return result
          end

          enhance_diagram_result(result)
        end

        def enhance_diagram_result(base_result)
          base_result.merge(
            diagram_type: diagram_type,
            session_id: session.id,
            metadata: build_diagram_metadata,
            cache_info: build_cache_info
          )
        end

        def build_diagram_metadata
          {
            generated_at: Time.current,
            diagram_type: diagram_type,
            available_types: self.class.available_types,
            cache_duration: cache_duration,
            supports_refresh: true
          }
        end

        def build_cache_info
          {
            cache_key: cache_key(diagram_type),
            expires_in: cache_duration,
            can_refresh: params[:refresh] != "true"
          }
        end

        def normalize_diagram_type(type)
          normalized = type.to_s.strip.downcase
          VALID_DIAGRAM_TYPES.include?(normalized) ? normalized : DEFAULT_DIAGRAM_TYPE
        end

        def validate_diagram_type
          return nil if VALID_DIAGRAM_TYPES.include?(diagram_type)

          error_msg = "Invalid diagram type '#{diagram_type}'. Valid types: #{VALID_DIAGRAM_TYPES.join(", ")}"
          log_error error_msg
          { error: error_msg }
        end

        def cache_duration
          # Longer cache for complex diagrams
          case diagram_type
          when "model_associations"
            2.hours
          when "database_tables"
            1.hour
          else
            30.minutes
          end
        end

        # Override cache key to include refresh parameter
        def cache_key(suffix = nil)
          key = super
          key += "_refresh" if params[:refresh] == "true"
          key
        end

        # Clear cache if refresh requested
        def with_cache(cache_suffix = nil, expires_in: 1.hour, &block)
          if params[:refresh] == "true"
            key = cache_key(cache_suffix)
            Rails.cache.delete(key)
            log_service_start("Cache cleared due to refresh request")
          end

          super
        end
      end
    end
  end
end
