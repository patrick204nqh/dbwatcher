# frozen_string_literal: true

module Dbwatcher
  # System information controller
  #
  # Handles web interface requests for system information display and refresh.
  # Provides both HTML and JSON responses for system information data.
  class SystemInfoController < BaseController
    before_action :ensure_system_info_enabled

    # Display system information page
    #
    # This method needs to be longer to properly handle both HTML and JSON responses,
    # including error handling for both formats.
    #
    # @return [void]
    # rubocop:disable Metrics/MethodLength
    def index
      @system_info = system_info_storage.cached_info
      @last_updated = @system_info[:collected_at]
      @collection_duration = @system_info[:collection_duration]
      @info_age = system_info_storage.info_age

      respond_to do |format|
        format.html
        format.json { render json: system_info_json_response(@system_info) }
      end
    rescue StandardError => e
      log_error "Failed to load system information: #{e.message}"

      respond_to do |format|
        format.html do
          @system_info = { error: e.message }
          @last_updated = nil
          @collection_duration = nil
          @info_age = nil
        end
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Refresh system information
    #
    # This method needs to be longer to properly handle both HTML and JSON responses,
    # including error handling for both formats.
    #
    # @return [void]
    # rubocop:disable Metrics/MethodLength
    def refresh
      @system_info = system_info_storage.refresh_info
      @last_updated = @system_info[:collected_at]
      @collection_duration = @system_info[:collection_duration]
      @info_age = 0

      respond_to do |format|
        format.html do
          redirect_to system_info_path, notice: "System information refreshed successfully"
        end
        format.json { render json: system_info_json_response(@system_info) }
      end
    rescue StandardError => e
      log_error "Failed to refresh system information: #{e.message}"

      respond_to do |format|
        format.html do
          redirect_to system_info_path, alert: "Failed to refresh system information: #{e.message}"
        end
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Clear system information cache
    #
    # @return [void]
    def clear_cache
      system_info_storage.clear_cache

      respond_to do |format|
        format.html do
          redirect_to system_info_path, notice: "System information cache cleared"
        end
        format.json { render json: { message: "Cache cleared successfully" } }
      end
    rescue StandardError => e
      log_error "Failed to clear cache: #{e.message}"

      respond_to do |format|
        format.html do
          redirect_to system_info_path, alert: "Failed to clear cache: #{e.message}"
        end
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end

    # Get system information summary for dashboard
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
      log_error "Failed to get system info summary: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end

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

      respond_to do |format|
        format.html do
          redirect_to root_path, alert: "System information collection is disabled"
        end
        format.json do
          render json: { error: "System information collection is disabled" }, status: :forbidden
        end
      end
    end

    # Format system information for JSON response
    #
    # @param info [Hash] system information data
    # @return [Hash] formatted JSON response
    def system_info_json_response(info)
      {
        status: :ok,
        data: info,
        timestamp: Time.current.iso8601,
        cache_age: system_info_storage.info_age&.round(2)
      }
    end
  end
end
