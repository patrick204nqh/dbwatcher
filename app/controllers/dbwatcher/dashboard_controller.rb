# frozen_string_literal: true

module Dbwatcher
  class DashboardController < BaseController
    def index
      dashboard_data = Dbwatcher::Services::DashboardDataAggregator.call
      @recent_sessions = dashboard_data[:recent_sessions]
      @active_tables = dashboard_data[:active_tables]
      @query_stats = dashboard_data[:query_stats]
      @active_tab = params[:tab] || "overview"

      # Add system information if enabled
      return unless Dbwatcher.configuration.system_info

      @system_info_summary = system_info_storage.summary
      @system_info = system_info_storage.cached_info
      @info_age = system_info_storage.info_age
    end

    def clear_all
      clear_storage_with_message(
        -> { Storage.clear_all },
        "All sessions and SQL logs",
        root_path
      )
    end

    private

    # Get system info storage instance
    #
    # @return [Storage::SystemInfoStorage] storage instance
    def system_info_storage
      @system_info_storage ||= Storage::SystemInfoStorage.new
    end
  end
end
