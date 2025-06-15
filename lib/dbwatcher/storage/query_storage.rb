# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative "query_validator"
require_relative "date_helper"

module Dbwatcher
  module Storage
    # Handles persistence and retrieval of database query logs
    #
    # This class manages the storage of query data organized by date.
    # Queries are stored in daily files with automatic cleanup and
    # size limiting based on configuration. Follows Ruby style guide
    # patterns for storage class organization.
    #
    # @example Basic usage
    #   storage = QueryStorage.new
    #   query = { sql: "SELECT * FROM users", timestamp: Time.current }
    #   storage.save(query)
    #   daily_queries = storage.find_by_date(Date.current)
    #
    # @example Advanced filtering
    #   queries = storage.find_by_date_range(1.week.ago..Time.current)
    #   recent_queries = storage.recent(limit: 50)
    class QueryStorage < BaseStorage
      # Include shared concerns
      include Concerns::Validatable
      include DateHelper

      # Configuration constants
      DEFAULT_CLEANUP_DAYS = 30
      QUERIES_DIRECTORY = "queries"
      MAX_QUERIES_PER_FILE = 1000

      # Validation rules
      validates_presence_of :sql, :timestamp

      # @return [String] path to queries directory
      attr_reader :queries_path

      # Initializes query storage with queries directory
      #
      # Creates the queries directory if it doesn't exist and sets up
      # the necessary file structure for date-based organization.
      #
      # @param storage_path [String, nil] custom storage path (optional)
      def initialize(storage_path = nil)
        super
        @queries_path = File.join(self.storage_path, QUERIES_DIRECTORY)
        file_manager.ensure_directory(@queries_path)
      end

      # Saves a query to date-based storage
      #
      # Validates the query and stores it in a daily file. Automatically
      # applies size limits based on configuration to prevent excessive
      # storage usage.
      #
      # @param query [Hash] query data containing at least :sql and :timestamp
      # @return [Boolean] true if saved successfully, false if invalid
      # @raise [ValidationError] if query data is invalid and strict mode enabled
      #
      # @example
      #   query = { sql: "SELECT * FROM users", timestamp: Time.current }
      #   storage.save(query) # => true
      def save(query)
        query_data = normalize_query_data(query)
        return false unless QueryValidator.valid?(query_data)

        date = format_date(query_data[:timestamp])
        query_file = date_file_path(@queries_path, date)

        queries = load_queries_from_file(query_file)
        queries = add_query_with_limits(queries, query_data)

        safe_write_json(query_file, queries)
      end

      # Alternative save method that raises on failure
      #
      # @param query [Hash] query data to save
      # @return [Boolean] true if saved successfully
      # @raise [ValidationError] if query data is invalid
      # @raise [StorageError] if save operation fails
      def save!(query)
        with_error_handling("save query") do
          save(query) or raise StorageError, "Failed to save query"
        end
      end

      # Finds all queries for a specific date
      #
      # @param date [Date, String] the date to load queries for
      # @return [Array<Hash>] array of query data for the specified date
      #
      # @example
      #   queries = storage.find_by_date(Date.current)
      #   queries.each { |q| puts q[:sql] }
      def find_by_date(date)
        query_file = date_file_path(@queries_path, date)
        safe_read_json(query_file)
      end

      # Finds queries within a date range
      #
      # @param date_range [Range] range of dates to search
      # @return [Array<Hash>] array of query data within the date range
      #
      # @example
      #   queries = storage.find_by_date_range(1.week.ago..Time.current)
      def find_by_date_range(date_range)
        date_range.flat_map do |date|
          find_by_date(date)
        end
      end

      # Finds recent queries across all dates
      #
      # @param limit [Integer] maximum number of queries to return
      # @return [Array<Hash>] array of recent query data
      def recent(limit: 100)
        all_queries = []
        dates_descending.each do |date|
          daily_queries = find_by_date(date)
          all_queries.concat(daily_queries)
          break if all_queries.size >= limit
        end

        all_queries
          .sort_by { |q| q[:timestamp] }
          .reverse
          .first(limit)
      end

      # Counts total number of queries
      #
      # @return [Integer] total number of stored queries
      def count
        query_files.sum do |file|
          safe_read_json(file).size
        end
      end

      # Counts queries for a specific date
      #
      # @param date [Date, String] date to count queries for
      # @return [Integer] number of queries for the date
      def count_by_date(date)
        find_by_date(date).size
      end

      # Loads all queries for a specific date (legacy method)
      #
      # @deprecated Use {#find_by_date} instead
      # @param date [Date, String] the date to load queries for
      # @return [Array<Hash>] array of query data
      def load_for_date(date)
        find_by_date(date)
      end

      # Removes old query files based on retention period
      #
      # @param days_to_keep [Integer] number of days of queries to retain
      # @return [Integer] number of files removed
      def cleanup_old_queries(days_to_keep = DEFAULT_CLEANUP_DAYS)
        cutoff_date = cleanup_cutoff_date(days_to_keep)
        removed_count = 0

        cleanup_files_older_than(cutoff_date) do
          removed_count += 1
        end

        removed_count
      end

      # Optimizes storage by removing duplicate queries
      #
      # @return [Integer] number of duplicates removed
      def optimize_storage
        duplicate_count = 0

        query_files.each do |file|
          queries = safe_read_json(file)
          unique_queries = queries.uniq { |q| [q[:sql], q[:timestamp]] }

          if unique_queries.size < queries.size
            duplicate_count += queries.size - unique_queries.size
            safe_write_json(file, unique_queries)
          end
        end

        duplicate_count
      end

      # Clears all query logs
      #
      # @return [Integer] number of files removed
      def clear_all
        with_error_handling("clear all queries") do
          # Count files before deleting
          file_count = count_query_files

          safe_delete_directory(queries_path)

          file_count
        end
      end

      # Counts the number of query files
      #
      # @return [Integer] number of query files
      def count_query_files
        return 0 unless Dir.exist?(@queries_path)

        query_files.count
      end

      private

      # Normalizes query data to hash format
      #
      # @param query [Hash, Object] query object or hash
      # @return [Hash] normalized query data
      def normalize_query_data(query)
        case query
        when Hash
          normalize_hash_keys(query)
        when ->(q) { q.respond_to?(:to_h) }
          normalize_hash_keys(query.to_h)
        else
          raise ValidationError, "Query must be a Hash or respond to :to_h"
        end
      end

      # Normalizes hash keys to symbols (Rails-compatible)
      #
      # @param hash [Hash] hash to normalize
      # @return [Hash] hash with symbolized keys
      def normalize_hash_keys(hash)
        if hash.respond_to?(:with_indifferent_access)
          hash.with_indifferent_access
        else
          hash.transform_keys(&:to_sym)
        end
      end

      # Loads existing queries from a file
      #
      # @param query_file [String] path to the query file
      # @return [Array<Hash>] existing queries or empty array
      def load_queries_from_file(query_file)
        safe_read_json(query_file)
      end

      # Adds a new query and applies daily limits
      #
      # @param queries [Array<Hash>] existing queries
      # @param new_query [Hash] new query to add
      # @return [Array<Hash>] updated queries with limits applied
      def add_query_with_limits(queries, new_query)
        updated_queries = queries + [new_query]
        apply_daily_limits(updated_queries)
      end

      # Applies daily query limits based on configuration
      #
      # @param queries [Array<Hash>] queries to limit
      # @return [Array<Hash>] limited queries (keeps most recent)
      def apply_daily_limits(queries)
        max_queries = Dbwatcher.configuration.max_query_logs_per_day || MAX_QUERIES_PER_FILE
        return queries if max_queries <= 0

        queries
          .sort_by { |q| normalize_timestamp_for_sorting(q[:timestamp]) }
          .last(max_queries)
      end

      # Removes query files older than the cutoff date
      #
      # @param cutoff_date [Time] files older than this date are removed
      # @yield [String] called for each file removed
      # @return [void]
      def cleanup_files_older_than(cutoff_date)
        safe_operation("cleanup old queries") do
          query_files.each do |file|
            if File.mtime(file) < cutoff_date
              file_manager.delete_file(file)
              yield file if block_given?
            end
          end
        end
      end

      # Returns all query files
      #
      # @return [Array<String>] paths to all query files
      def query_files
        file_manager.glob_files(File.join(@queries_path, "*.json"))
      end

      # Normalizes timestamp for sorting to handle mixed string/Time types
      #
      # @param timestamp [String, Time, nil] timestamp to normalize
      # @return [Time] normalized timestamp
      def normalize_timestamp_for_sorting(timestamp)
        case timestamp
        when Time
          timestamp
        when String
          Time.parse(timestamp)
        else
          Time.at(0) # Fallback for nil or invalid timestamps
        end
      rescue ArgumentError
        Time.at(0) # Fallback for unparseable strings
      end

      # Returns dates in descending order based on existing files
      #
      # @return [Array<Date>] sorted dates
      def dates_descending
        query_files
          .map { |file| File.basename(file, ".json") }
          .map do |filename|
          Date.parse(filename)
          rescue StandardError
            nil
        end
          .compact
          .sort
          .reverse
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
