# frozen_string_literal: true

module Dbwatcher
  module Dashboard
    class SystemInfoController < BaseController
      def index
        return redirect_to root_path unless Dbwatcher.configuration.collect_system_info

        @system_info_summary = system_info_storage.summary
        @system_info = system_info_storage.cached_info
        @info_age = system_info_storage.info_age
      end

      def refresh
        system_info_storage.refresh_info

        respond_to do |format|
          format.json do
            render json: refresh_success_response
          end
        end
      rescue StandardError => e
        respond_to do |format|
          format.json do
            render json: { success: false, error: e.message }, status: :internal_server_error
          end
        end
      end

      def clear_cache
        system_info_storage.clear_cache

        respond_to do |format|
          format.json do
            render json: clear_cache_success_response
          end
        end
      rescue StandardError => e
        respond_to do |format|
          format.json do
            render json: { success: false, error: e.message }, status: :internal_server_error
          end
        end
      end

      private

      # Get system info storage instance
      #
      # @return [Storage::SystemInfoStorage] storage instance
      def system_info_storage
        @system_info_storage ||= Storage::SystemInfoStorage.new
      end

      def refresh_success_response
        {
          success: true,
          message: "System information refreshed successfully",
          data: system_info_storage.cached_info,
          summary: system_info_storage.summary
        }
      end

      def clear_cache_success_response
        {
          success: true,
          message: "System information cache cleared successfully"
        }
      end
    end
  end
end
