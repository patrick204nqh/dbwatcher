# frozen_string_literal: true

require_relative "query_validator"
require_relative "date_helper"

module Dbwatcher
  module Storage
    class QueryStorage < Base
      include DateHelper

      def initialize
        super
        @queries_path = File.join(storage_path, "queries")
        file_manager.ensure_directory(@queries_path)
      end

      def save(query)
        return false unless QueryValidator.valid?(query)

        date = format_date(query[:timestamp])
        query_file = date_file_path(@queries_path, date)

        queries = load_queries_from_file(query_file)
        queries = add_query_with_limits(queries, query)

        safe_write_json(query_file, queries)
      end

      def load_for_date(date)
        query_file = date_file_path(@queries_path, date)
        safe_read_json(query_file)
      end

      def cleanup_old_queries(days_to_keep = DEFAULT_CLEANUP_DAYS)
        cutoff_date = cleanup_cutoff_date(days_to_keep)
        cleanup_files_older_than(cutoff_date)
      end

      private

      def load_queries_from_file(query_file)
        safe_read_json(query_file)
      end

      def add_query_with_limits(queries, new_query)
        queries << new_query
        apply_daily_limits(queries)
      end

      def apply_daily_limits(queries)
        max_queries = Dbwatcher.configuration.max_query_logs_per_day
        return queries unless max_queries&.positive?

        queries.last(max_queries)
      end

      def cleanup_files_older_than(cutoff_date)
        safe_operation("cleanup old queries") do
          file_manager.glob_files(File.join(@queries_path, "*.json")).each do |file|
            file_manager.delete_file(file) if File.mtime(file) < cutoff_date
          end
        end
      end
    end
  end
end
