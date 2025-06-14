# frozen_string_literal: true

module Dbwatcher
  module Storage
    class QueryStorage < Base
      def initialize
        super
        @queries_path = File.join(storage_path, "queries")
        FileUtils.mkdir_p(@queries_path)
      end

      def save(query)
        return unless query

        date = query[:timestamp].strftime("%Y-%m-%d")
        query_file = File.join(@queries_path, "#{date}.json")

        queries = load_for_date(date)
        queries << query

        # Apply limits
        max_queries = Dbwatcher.configuration.max_query_logs_per_day
        queries = queries.last(max_queries) if queries.count > max_queries

        safe_write_json(query_file, queries)
      end

      def load_for_date(date)
        query_file = File.join(@queries_path, "#{date}.json")
        safe_read_json(query_file)
      end

      def cleanup_old_queries(days_to_keep = 30)
        cutoff_date = Time.now - (days_to_keep * 24 * 60 * 60)

        Dir.glob(File.join(@queries_path, "*.json")).each do |file|
          File.delete(file) if File.mtime(file) < cutoff_date
        end
      rescue StandardError => e
        warn "Failed to cleanup old queries: #{e.message}"
      end
    end
  end
end
