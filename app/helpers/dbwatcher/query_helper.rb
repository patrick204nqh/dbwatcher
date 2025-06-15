# frozen_string_literal: true

module Dbwatcher
  module QueryHelper
    # Filter queries by operation type
    def filter_queries_by_operation(queries, operation)
      return queries unless operation.present?

      queries.select { |q| q[:operation] == operation }
    end

    # Filter queries by table name
    def filter_queries_by_table(queries, table_name)
      return queries unless table_name.present?

      queries.select { |q| q[:tables]&.include?(table_name) }
    end

    # Filter queries by minimum duration
    def filter_queries_by_duration(queries, min_duration)
      return queries unless min_duration.present?

      min_duration_float = min_duration.to_f
      queries.select { |q| query_exceeds_duration?(q, min_duration_float) }
    end

    # Sort queries by timestamp (newest first)
    def sort_queries_by_timestamp(queries)
      queries.sort_by { |q| -(q[:timestamp] ? Time.parse(q[:timestamp]).to_i : 0) }
    end

    # Calculate query statistics for dashboard
    def calculate_query_statistics(queries)
      {
        total: queries.count,
        slow_queries: queries.count { |q| q["duration"] && q["duration"] > 100 },
        by_operation: group_queries_by_operation(queries)
      }
    rescue StandardError
      {
        total: 0,
        slow_queries: 0,
        by_operation: {}
      }
    end

    # Format query duration for display
    def format_query_duration(duration)
      return "N/A" unless duration

      if duration < 1
        "#{(duration * 1000).round}ms"
      elsif duration < 1000
        "#{duration.round(2)}s"
      else
        "#{(duration / 1000).round(2)}s"
      end
    end

    private

    def query_exceeds_duration?(query, min_duration)
      duration = query[:duration]
      duration && duration >= min_duration
    end

    def group_queries_by_operation(queries)
      queries.group_by { |q| q[:operation] || "UNKNOWN" }
             .transform_values(&:count)
    end
  end
end
