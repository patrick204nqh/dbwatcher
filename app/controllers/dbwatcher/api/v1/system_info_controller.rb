# frozen_string_literal: true

module Dbwatcher
  module Api
    module V1
      # System information API controller
      #
      # Provides RESTful API endpoints for system information access.
      # Supports JSON responses for programmatic access to system data.
      # rubocop:disable Metrics/ClassLength
      class SystemInfoController < BaseController
        before_action :ensure_system_info_enabled

        # Get complete system information
        #
        # @return [void]
        def index
          info = system_info_storage.cached_info

          render json: {
            status: :ok,
            data: info,
            timestamp: Time.current.iso8601,
            cache_age: system_info_storage.info_age&.round(2)
          }
        rescue StandardError => e
          log_error "API: Failed to get system information: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Refresh system information
        #
        # @return [void]
        def refresh
          info = system_info_storage.refresh_info

          render json: {
            status: :ok,
            data: info,
            timestamp: Time.current.iso8601,
            message: "System information refreshed successfully"
          }
        rescue StandardError => e
          log_error "API: Failed to refresh system information: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Get machine information only
        #
        # @return [void]
        def machine
          info = system_info_storage.cached_info

          render json: {
            status: :ok,
            data: info[:machine] || {},
            timestamp: Time.current.iso8601,
            cache_age: system_info_storage.info_age&.round(2)
          }
        rescue StandardError => e
          log_error "API: Failed to get machine information: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Get database information only
        #
        # @return [void]
        def database
          info = system_info_storage.cached_info

          render json: {
            status: :ok,
            data: info[:database] || {},
            timestamp: Time.current.iso8601,
            cache_age: system_info_storage.info_age&.round(2)
          }
        rescue StandardError => e
          log_error "API: Failed to get database information: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Get runtime information only
        #
        # @return [void]
        def runtime
          info = system_info_storage.cached_info

          render json: {
            status: :ok,
            data: info[:runtime] || {},
            timestamp: Time.current.iso8601,
            cache_age: system_info_storage.info_age&.round(2)
          }
        rescue StandardError => e
          log_error "API: Failed to get runtime information: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Get system information summary
        #
        # @return [void]
        def summary
          summary_data = system_info_storage.summary

          render json: {
            status: :ok,
            data: summary_data,
            timestamp: Time.current.iso8601
          }
        rescue StandardError => e
          log_error "API: Failed to get system info summary: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Clear system information cache
        #
        # @return [void]
        def clear_cache
          system_info_storage.clear_cache

          render json: {
            status: :ok,
            message: "System information cache cleared successfully",
            timestamp: Time.current.iso8601
          }
        rescue StandardError => e
          log_error "API: Failed to clear cache: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end

        # Get cache status and metadata
        #
        # @return [void]
        # rubocop:disable Metrics/MethodLength
        def cache_status
          info_available = system_info_storage.info_available?
          cache_age = system_info_storage.info_age

          render json: {
            status: :ok,
            data: {
              cache_available: info_available,
              cache_age: cache_age&.round(2),
              cache_expired: cache_age && cache_age > Dbwatcher.configuration.system_info_cache_duration,
              max_cache_age: Dbwatcher.configuration.system_info_cache_duration,
              refresh_interval: Dbwatcher.configuration.system_info_refresh_interval
            },
            timestamp: Time.current.iso8601
          }
        rescue StandardError => e
          log_error "API: Failed to get cache status: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end
        # rubocop:enable Metrics/MethodLength

        private

        # Get system info storage instance
        #
        # @return [Storage::SystemInfoStorage] storage instance
        def system_info_storage
          @system_info_storage ||= Storage::SystemInfoStorage.new
        end

        # Check if system information collection is enabled
        #
        # @return [void]
        def ensure_system_info_enabled
          return if Dbwatcher.configuration.collect_system_info

          render json: {
            error: "System information collection is disabled",
            status: :forbidden
          }, status: :forbidden
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
