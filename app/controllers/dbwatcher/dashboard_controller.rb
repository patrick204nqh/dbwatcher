# frozen_string_literal: true

module Dbwatcher
  class DashboardController < BaseController
    def index
      dashboard_data = Dbwatcher::Services::DashboardDataAggregator.call
      @recent_sessions = dashboard_data[:recent_sessions]
      @active_tables = dashboard_data[:active_tables]
      @query_stats = dashboard_data[:query_stats]
    end
  end
end
