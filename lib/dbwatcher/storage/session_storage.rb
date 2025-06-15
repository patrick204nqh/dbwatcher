# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative "session_operations"
require_relative "null_session"

module Dbwatcher
  module Storage
    # Handles persistence and retrieval of database monitoring sessions
    #
    # This class manages the storage of session data including metadata,
    # timestamps, and associated database changes. Sessions are stored
    # as individual JSON files with an index for efficient querying.
    # Follows Ruby style guide patterns for storage class organization.
    #
    # @example Basic usage
    #   storage = SessionStorage.new
    #   session = Session.new(id: "123", name: "Test Session")
    #   storage.save(session)
    #   loaded_session = storage.find("123")
    #
    # @see Session
    # @see NullSession
    class SessionStorage < BaseStorage
      # Include shared concerns
      include Concerns::Validatable
      include Concerns::DataNormalizer

      # Configuration constants
      DEFAULT_INDEX_FILENAME = "index.json"
      SESSIONS_DIRECTORY = "sessions"

      # Validation rules
      validates_presence_of :id

      # @return [String] path to sessions directory
      attr_reader :sessions_path

      # @return [String] path to index file
      attr_reader :index_file

      # @return [SessionOperations] operations helper
      attr_reader :operations

      # @return [Mutex] thread safety mutex
      attr_reader :mutex

      # Initializes a new SessionStorage instance
      #
      # Sets up the necessary directories and index files for session storage.
      # Creates the sessions directory and index file if they don't exist.
      # Includes thread safety for concurrent operations.
      #
      # @param storage_path [String, nil] custom storage path (optional)
      def initialize(storage_path = nil)
        super
        @sessions_path = File.join(self.storage_path, SESSIONS_DIRECTORY)
        @index_file = File.join(self.storage_path, DEFAULT_INDEX_FILENAME)
        @operations = SessionOperations.new(@sessions_path, @index_file)
        @mutex = Mutex.new

        setup_directories
      end

      # Persists a session to storage
      #
      # Saves the session data to a JSON file and updates the session index.
      # Automatically triggers cleanup of old sessions after successful save.
      # Uses thread safety to prevent concurrent write conflicts.
      #
      # @param session [Session, Hash] the session object or hash to save
      # @return [Boolean] true if saved successfully, false otherwise
      # @raise [ValidationError] if session data is invalid
      #
      # @example
      #   session = Session.new(id: "123", name: "Test")
      #   storage.save(session) # => true
      # rubocop:disable Naming/PredicateMethod
      def save(session)
        session_data = normalize_session_data(session)
        validate_session_data!(session_data)

        mutex.synchronize do
          persist_session_file(session_data)
          update_session_index(session_data)
          trigger_cleanup
        end

        true
      end
      # rubocop:enable Naming/PredicateMethod

      # Alternative save method that raises on failure
      #
      # @param session [Session, Hash] the session object or hash to save
      # @return [Boolean] true if saved successfully
      # @raise [ValidationError] if session data is invalid
      # @raise [StorageError] if save operation fails
      def save!(session)
        with_error_handling("save session") do
          save(session) or raise StorageError, "Failed to save session"
        end
      end

      # Finds a session by ID
      #
      # Retrieves session data from storage and constructs a Session object.
      # Returns nil if the session is not found.
      #
      # @param id [String, Integer] the session ID to find
      # @return [Session, nil] the loaded session or nil if not found
      #
      # @example
      #   session = storage.find("123")
      #   puts session.name if session
      def find(id)
        return nil unless valid_id?(id)

        session_data = load_session_data(id)
        return nil if session_data.empty?

        build_session_from_data(session_data)
      end

      # Finds a session by ID or raises an exception
      #
      # @param id [String, Integer] the session ID to find
      # @return [Session] the loaded session
      # @raise [SessionNotFoundError] if session is not found
      def find!(id)
        find(id) or raise SessionNotFoundError, "Session with id '#{id}' not found"
      end

      # Loads a session by ID (legacy method, use find instead)
      #
      # @deprecated Use {#find} instead
      # @param id [String, Integer] the session ID to load
      # @return [Session, NullSession] the loaded session or null object
      def load(id)
        find(id) || NullSession.instance
      end

      # Returns all session summaries from the index
      #
      # @return [Array<Hash>] array of session summary hashes
      def all
        safe_read_json(index_file)
      end

      # Checks if a session exists
      #
      # @param id [String, Integer] the session ID to check
      # @return [Boolean] true if session exists
      def exists?(id)
        return false unless valid_id?(id)

        session_file = operations.session_file_path(id)
        file_manager.file_exists?(session_file)
      end

      # Counts total number of sessions
      #
      # @return [Integer] number of sessions
      def count
        all.size
      end

      # Clears all session storage
      #
      # Removes all session files and reinitializes the storage structure.
      # This operation cannot be undone.
      #
      # @return [Integer] number of files removed
      def clear_all
        with_error_handling("clear all sessions") do
          # Count files before deleting
          file_count = count_session_files

          safe_delete_directory(sessions_path)
          safe_write_json(index_file, [])
          setup_directories
          touch_updated_at

          file_count
        end
      end

      # Removes old session files based on configuration
      #
      # Automatically called after each save operation to maintain
      # storage size within configured limits.
      #
      # @return [void]
      def cleanup_old_sessions
        return unless cleanup_enabled?

        cutoff_date = calculate_cleanup_cutoff
        remove_old_session_files(cutoff_date)
      end

      private

      # Sets up required directories and files
      #
      # @return [void]
      def setup_directories
        file_manager.ensure_directory(sessions_path)
        file_manager.write_json(index_file, []) unless File.exist?(index_file)
      end

      # Validates session data
      #
      # @param session_data [Hash] session data to validate
      # @return [void]
      # @raise [ValidationError] if data is invalid
      def validate_session_data!(session_data)
        validate_presence!(session_data, :id)
        validate_id!(session_data[:id])
      end

      # Persists session data to file
      #
      # @param session_data [Hash] session data to persist
      # @return [void]
      def persist_session_file(session_data)
        session_file = operations.session_file_path(session_data[:id])
        safe_write_json(session_file, session_data)
      end

      # Updates the session index
      #
      # @param session_data [Hash] session data for index update
      # @return [void]
      def update_session_index(session_data)
        index = safe_read_json(index_file)
        session_summary = operations.build_session_summary(session_data)

        updated_index = [session_summary] + index
        limited_index = operations.apply_session_limits(updated_index)

        safe_write_json(index_file, limited_index)
      end

      # Triggers cleanup of old sessions
      #
      # @return [void]
      def trigger_cleanup
        cleanup_old_sessions
      end

      # Loads session data from file
      #
      # @param id [String] session ID
      # @return [Hash] session data or empty hash
      def load_session_data(id)
        session_file = operations.session_file_path(id)
        safe_read_json(session_file, {})
      end

      # Builds session object from data
      #
      # @param data [Hash] session data
      # @return [Session] session object
      def build_session_from_data(data)
        Storage::Session.new(data)
      rescue StandardError => e
        log_error("Failed to build session from data", e)
        raise CorruptedDataError, "Session data is corrupted: #{e.message}"
      end

      # Counts the number of session files
      #
      # @return [Integer] number of session files
      def count_session_files
        return 0 unless Dir.exist?(sessions_path)

        Dir.glob(File.join(sessions_path, "*.json")).count
      end

      # Checks if cleanup is enabled
      #
      # @return [Boolean] true if cleanup is enabled
      def cleanup_enabled?
        Dbwatcher.configuration.auto_clean_after_days&.positive?
      end

      # Calculates cleanup cutoff date
      #
      # @return [Time] cutoff date for cleanup
      def calculate_cleanup_cutoff
        days = Dbwatcher.configuration.auto_clean_after_days
        current_time - (days * 24 * 60 * 60)
      end

      # Removes old session files
      #
      # @param cutoff_date [Time] files older than this date are removed
      # @return [void]
      def remove_old_session_files(cutoff_date)
        safe_operation("cleanup old sessions") do
          Dir.glob(File.join(sessions_path, "*.json")).each do |file|
            File.delete(file) if File.mtime(file) < cutoff_date
          end
        end
      end

      # Returns current time (compatible with and without Rails)
      #
      # @return [Time] current time
      def current_time
        if defined?(Time.current)
          Time.current
        else
          Time.now
        end
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
