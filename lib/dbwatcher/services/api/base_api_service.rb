# frozen_string_literal: true

module Dbwatcher
  module Services
    module Api
      # Base class for API data services
      #
      # Provides common functionality for API endpoints including
      # session handling, caching, and error handling.
      class BaseApiService < BaseService
        attr_reader :session, :params

        def initialize(session, params = {})
          @session = session
          @params = params
          super()
        end

        protected

        # Build cache key for session-based data
        #
        # @param suffix [String] additional cache key suffix
        # @return [String] cache key
        def cache_key(suffix = nil)
          key = "api_#{service_name}_#{session.id}"
          key += "_#{suffix}" if suffix
          key
        end

        # Get service name for logging and caching
        #
        # @return [String] service name
        def service_name
          self.class.name.demodulize.underscore.gsub("_service", "")
        end

        # Execute with caching
        #
        # @param cache_suffix [String] optional cache suffix
        # @param expires_in [ActiveSupport::Duration] cache expiration
        # @yield block to execute if cache miss
        # @return [Object] cached or fresh result
        def with_cache(cache_suffix = nil, _expires_in: 1.hour)
          cache_key(cache_suffix)

          # Rails.cache.fetch(key, expires_in: expires_in) do
          log_service_start("Cache miss, generating fresh data")
          yield
          # end
        end

        # Handle service errors consistently
        #
        # @param error [StandardError] the error to handle
        # @return [Hash] error response
        def handle_error(error)
          log_error "Error in #{service_name}: #{error.message}", error: error
          { error: error.message }
        end

        # Validate session exists
        #
        # @return [Hash, nil] error hash if session invalid, nil if valid
        def validate_session
          return nil if session

          error_msg = "Session not found"
          log_error error_msg
          { error: error_msg }
        end

        # Previously had pagination parameters method here
        # Now removed to show all data without pagination

        # Parse filter parameters (override in subclasses)
        #
        # @return [Hash] filter parameters
        def filter_params
          # Expect params to be a Hash from the controller
          return {} if params.nil?

          # Extract only the filter-related keys
          # Make sure we handle the case when params doesn't respond to slice
          if params.respond_to?(:slice)
            params.slice(:table, :operation).compact
          else
            {}
          end
        end
      end
    end
  end
end
