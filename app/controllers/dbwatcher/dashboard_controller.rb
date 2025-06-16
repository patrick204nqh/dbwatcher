# frozen_string_literal: true

module Dbwatcher
  class DashboardController < BaseController
    def index
      dashboard_data = Dbwatcher::Services::DashboardDataAggregator.call
      @recent_sessions = dashboard_data[:recent_sessions]
      @active_tables = dashboard_data[:active_tables]
      @query_stats = dashboard_data[:query_stats]
    end

    def clear_all
      clear_storage_with_message(
        -> { Storage.clear_all },
        "All sessions and SQL logs",
        root_path
      )
    end
  end
end
