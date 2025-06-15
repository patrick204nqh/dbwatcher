# frozen_string_literal: true

module Dbwatcher
  module Services
    # Service object for aggregating dashboard statistics
    # Provides recent sessions, active tables, and query metrics
    class DashboardDataAggregator
      include Dbwatcher::Logging

      # @return [Hash] dashboard statistics with recent_sessions, active_tables, query_stats
      def self.call
        new.call
      end

      def call
        log_info "Starting dashboard data aggregation"
        start_time = Time.current

        result = {
          recent_sessions: fetch_recent_sessions,
          active_tables: calculate_active_tables,
          query_stats: aggregate_query_statistics
        }

        duration = Time.current - start_time
        log_info "Completed dashboard aggregation in #{duration.round(3)}s", {
          recent_sessions_count: result[:recent_sessions].length,
          active_tables_count: result[:active_tables].length,
          total_queries: result[:query_stats][:total]
        }

        result
      end

      private

      # @return [Array<Hash>] most recent 5 sessions
      def fetch_recent_sessions
        Storage.sessions.all.first(5)
      end

      # @return [Array<Array>] top 10 most active tables with change counts
      def calculate_active_tables
        table_activity_counts = Hash.new(0)

        Storage.sessions.all.first(10).each do |session_info|
          session = Storage.sessions.find(session_info[:id])
          next unless session

          session.changes.each do |change|
            table_name = change[:table_name]
            table_activity_counts[table_name] += 1 if table_name
          end
        end

        table_activity_counts
          .sort_by { |_table, count| -count }
          .first(10)
      end

      # @return [Hash] query statistics including totals and breakdowns
      def aggregate_query_statistics
        date = Date.current.strftime("%Y-%m-%d")
        log_debug "Aggregating query statistics for date: #{date}"

        queries = fetch_queries_for_date(date)
        build_query_statistics(queries)
      rescue StandardError => e
        log_error "Failed to aggregate query statistics: #{e.message}"
        default_query_statistics
      end

      def fetch_queries_for_date(date)
        Storage.queries.for_date(date).all
      end

      def build_query_statistics(queries)
        slow_queries_count = count_slow_queries(queries)
        operations_breakdown = group_queries_by_operation(queries)

        log_query_statistics_summary(queries, slow_queries_count, operations_breakdown)

        {
          total: queries.count,
          slow_queries: slow_queries_count,
          by_operation: operations_breakdown
        }
      end

      def log_query_statistics_summary(queries, slow_queries_count, operations_breakdown)
        log_debug "Query stats aggregated", {
          total_queries: queries.count,
          slow_queries: slow_queries_count,
          operations: operations_breakdown.keys.join(", ")
        }
      end

      def count_slow_queries(queries)
        queries.count { |query| query_is_slow?(query) }
      end

      def query_is_slow?(query)
        query["duration"] && query["duration"] > 100
      end

      def group_queries_by_operation(queries)
        queries
          .group_by { |query| query[:operation] || "UNKNOWN" }
          .transform_values(&:count)
      end

      def default_query_statistics
        {
          total: 0,
          slow_queries: 0,
          by_operation: {}
        }
      end
    end
  end
end
