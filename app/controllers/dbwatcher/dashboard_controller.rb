# frozen_string_literal: true

module Dbwatcher
  class DashboardController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @recent_sessions = Storage.all_sessions.first(5)
      @active_tables = calculate_active_tables
      @query_stats = calculate_query_stats
    end

    private

    def calculate_active_tables
      # Get tables with most recent changes
      tables = Hash.new(0)

      Storage.all_sessions.first(10).each do |session_info|
        session = Storage.load_session(session_info[:id])
        next unless session

        session.changes.each do |change|
          table_name = change["table_name"] || change[:table_name]
          tables[table_name] += 1
        end
      end

      tables.sort_by { |_, count| -count }.first(10)
    end

    def calculate_query_stats
      date = Date.current.strftime("%Y-%m-%d")
      queries = Storage.load_queries_for_date(date)

      {
        total: queries.count,
        slow_queries: queries.count { |q| q["duration"] && q["duration"] > 100 },
        by_operation: queries.group_by { |q| q["operation"] || "UNKNOWN" }
                             .transform_values(&:count)
      }
    rescue StandardError
      {
        total: 0,
        slow_queries: 0,
        by_operation: {}
      }
    end
  end
end
