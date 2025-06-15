# frozen_string_literal: true

require_relative "change_processor"

module Dbwatcher
  module Storage
    # Handles retrieval and processing of table change data
    #
    # This class provides access to database table changes by coordinating
    # with the change processor to aggregate and filter table modifications
    # from stored session data. Follows Ruby style guide patterns for
    # storage class organization.
    #
    # @example Basic usage
    #   storage = TableStorage.new(session_storage)
    #   changes = storage.find_changes("users")
    #   changes.each { |change| puts "#{change[:operation]} on #{change[:table]}" }
    #
    # @example Advanced filtering
    #   recent_changes = storage.find_recent_changes("users", limit: 10)
    #   filtered_changes = storage.find_changes_by_operation("users", "INSERT")
    class TableStorage < BaseStorage
      # Include validation capabilities
      include Concerns::Validatable

      # Configuration constants
      DEFAULT_CHANGE_LIMIT = 100
      SUPPORTED_OPERATIONS = %w[INSERT UPDATE DELETE].freeze

      # @return [ChangeProcessor] processor for handling table changes
      attr_reader :change_processor

      # @return [SessionStorage] session storage dependency
      attr_reader :session_storage

      # Initializes table storage with session storage dependency
      #
      # @param session_storage [SessionStorage] storage instance for session data
      # @param storage_path [String, nil] custom storage path (optional)
      def initialize(session_storage, storage_path = nil)
        super(storage_path)
        @session_storage = session_storage
        @change_processor = ChangeProcessor.new(session_storage)
      end

      # Finds all changes for a specific table
      #
      # Retrieves and processes all database changes related to the specified
      # table from stored session data. Returns an empty array if the table
      # name is invalid or no changes are found.
      #
      # @param table_name [String] name of the table to load changes for
      # @param options [Hash] filtering options
      # @option options [Integer] :limit maximum number of changes to return
      # @option options [String] :operation filter by operation type (INSERT, UPDATE, DELETE)
      # @option options [Time] :since only return changes after this time
      # @return [Array<Hash>] array of change records for the table
      #
      # @example
      #   changes = storage.find_changes("users")
      #   puts "Found #{changes.length} changes for users table"
      #
      # @example With filtering
      #   recent_inserts = storage.find_changes("users", operation: "INSERT", limit: 50)
      def find_changes(table_name, **options)
        validate_table_name!(table_name)
        validate_operation!(options[:operation]) if options[:operation]

        changes = change_processor.process_table_changes(table_name)
        apply_filters(changes, **options)
      rescue StandardError => e
        log_error("Failed to load changes for table #{table_name}", e)
        []
      end

      # Finds changes for a table with a specific operation
      #
      # @param table_name [String] name of the table
      # @param operation [String] operation type (INSERT, UPDATE, DELETE)
      # @param limit [Integer] maximum number of changes to return
      # @return [Array<Hash>] filtered change records
      def find_changes_by_operation(table_name, operation, limit: DEFAULT_CHANGE_LIMIT)
        find_changes(table_name, operation: operation, limit: limit)
      end

      # Finds recent changes for a table
      #
      # @param table_name [String] name of the table
      # @param limit [Integer] maximum number of changes to return
      # @param since [Time] only return changes after this time
      # @return [Array<Hash>] recent change records
      def find_recent_changes(table_name, limit: DEFAULT_CHANGE_LIMIT, since: 1.day.ago)
        find_changes(table_name, limit: limit, since: since)
      end

      # Counts total changes for a table
      #
      # @param table_name [String] name of the table
      # @return [Integer] number of changes for the table
      def count_changes(table_name)
        find_changes(table_name).size
      end

      # Counts changes by operation type
      #
      # @param table_name [String] name of the table
      # @return [Hash] hash with operation types as keys and counts as values
      def count_changes_by_operation(table_name)
        changes = find_changes(table_name)

        SUPPORTED_OPERATIONS.each_with_object({}) do |operation, counts|
          counts[operation] = changes.count { |change| change[:operation] == operation }
        end
      end

      # Lists all tables that have changes
      #
      # @return [Array<String>] array of table names with changes
      def tables_with_changes
        change_processor.tables_with_changes
      rescue StandardError => e
        log_error("Failed to load tables with changes", e)
        []
      end

      # Checks if a table has any changes
      #
      # @param table_name [String] name of the table to check
      # @return [Boolean] true if table has changes
      def changes?(table_name)
        return false unless valid_table_name?(table_name)

        count_changes(table_name).positive?
      end

      # Legacy method for backward compatibility
      #
      # @deprecated Use {#find_changes} instead
      # @param table_name [String] name of the table to load changes for
      # @return [Array<Hash>] array of change records
      def load_changes(table_name)
        find_changes(table_name)
      end

      private

      # Validates table name for presence and format
      #
      # @param table_name [String] table name to validate
      # @return [void]
      # @raise [ValidationError] if table name is invalid
      def validate_table_name!(table_name)
        raise ValidationError, "Table name cannot be nil or empty" if table_name.nil? || table_name.to_s.strip.empty?

        return unless table_name.to_s.include?(" ")

        raise ValidationError, "Table name cannot contain spaces"
      end

      # Validates operation type
      #
      # @param operation [String] operation to validate
      # @return [void]
      # @raise [ValidationError] if operation is invalid
      def validate_operation!(operation)
        return if SUPPORTED_OPERATIONS.include?(operation.to_s.upcase)

        raise ValidationError,
              "Unsupported operation: #{operation}. Must be one of: #{SUPPORTED_OPERATIONS.join(", ")}"
      end

      # Checks if table name is valid
      #
      # @param table_name [String] table name to check
      # @return [Boolean] true if table name is valid
      def valid_table_name?(table_name)
        !table_name.nil? && !table_name.to_s.strip.empty?
      end

      # Applies filtering options to changes
      #
      # @param changes [Array<Hash>] changes to filter
      # @param options [Hash] filtering options
      # @return [Array<Hash>] filtered changes
      def apply_filters(changes, **options)
        filtered_changes = changes
        filtered_changes = filter_by_operation(filtered_changes, options[:operation]) if options[:operation]
        filtered_changes = filter_by_time(filtered_changes, options[:since]) if options[:since]
        filtered_changes = apply_limit(filtered_changes, options[:limit]) if options[:limit]
        filtered_changes
      end

      # Filters changes by operation type
      #
      # @param changes [Array<Hash>] changes to filter
      # @param operation [String, Symbol] operation to filter by
      # @return [Array<Hash>] filtered changes
      def filter_by_operation(changes, operation)
        operation_str = operation.to_s.upcase
        changes.select { |change| change[:operation] == operation_str }
      end

      # Filters changes by timestamp
      #
      # @param changes [Array<Hash>] changes to filter
      # @param since_time [Time] minimum timestamp
      # @return [Array<Hash>] filtered changes
      def filter_by_time(changes, since_time)
        changes.select do |change|
          change_time = parse_timestamp(change[:timestamp])
          change_time && change_time >= since_time
        end
      end

      # Applies limit to changes (returns most recent)
      #
      # @param changes [Array<Hash>] changes to limit
      # @param limit [Integer] maximum number of changes to return
      # @return [Array<Hash>] limited changes
      def apply_limit(changes, limit)
        changes.sort_by { |change| change[:timestamp] }
               .reverse
               .first(limit)
      end

      # Parses timestamp safely
      #
      # @param timestamp [String, Time] timestamp to parse
      # @return [Time, nil] parsed time or nil if invalid
      def parse_timestamp(timestamp)
        Time.parse(timestamp.to_s)
      rescue StandardError
        nil
      end
    end
  end
end
