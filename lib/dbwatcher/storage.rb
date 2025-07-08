# frozen_string_literal: true

require_relative "storage/base_storage"
require_relative "storage/concerns/error_handler"
require_relative "storage/concerns/timestampable"
require_relative "storage/concerns/validatable"
require_relative "storage/concerns/data_normalizer"
require_relative "storage/session_storage"
require_relative "storage/query_storage"
require_relative "storage/table_storage"
require_relative "storage/session_query"
require_relative "storage/system_info_storage"
require_relative "storage/api/base_api"
require_relative "storage/api/query_api"
require_relative "storage/api/table_api"
require_relative "storage/api/session_api"
require_relative "storage/session"
require_relative "storage/errors"

module Dbwatcher
  # Storage module provides the main interface for database monitoring data persistence
  #
  # This module acts as a facade for different storage backends and provides
  # clean API entry points for sessions, queries, and tables. It manages
  # storage instances and provides cleanup operations.
  #
  # @example Basic usage
  #   Dbwatcher::Storage.sessions.create("My Session")
  #   Dbwatcher::Storage.sessions.recent.with_changes
  #   Dbwatcher::Storage.queries.save(query_data)
  #   Dbwatcher::Storage.tables.changes_for("users")
  #
  # @example Cleanup operations
  #   Dbwatcher::Storage.cleanup_old_sessions
  #   Dbwatcher::Storage.clear_all
  # @see SessionAPI
  # @see QueryAPI
  # @see TableAPI
  module Storage
    class << self
      # Provides access to session operations
      #
      # @return [SessionAPI] session API interface
      # @example
      #   Dbwatcher::Storage.sessions.create("My Session")
      #   Dbwatcher::Storage.sessions.all
      #   Dbwatcher::Storage.sessions.recent.with_changes
      def sessions
        @sessions ||= Api::SessionAPI.new(session_storage)
      end

      # Provides access to query operations
      #
      # @return [QueryAPI] query API interface
      # @example
      #   Dbwatcher::Storage.queries.save(query_data)
      #   Dbwatcher::Storage.queries.for_date(Date.today)
      def queries
        @queries ||= Api::QueryAPI.new(query_storage)
      end

      # Provides access to table operations
      #
      # @return [TableAPI] table API interface
      # @example
      #   Dbwatcher::Storage.tables.changes_for("users")
      #   Dbwatcher::Storage.tables.recent_changes
      def tables
        @tables ||= Api::TableAPI.new(table_storage)
      end

      # Provides access to system information operations
      #
      # @return [SystemInfoStorage] system info storage instance
      # @example
      #   Dbwatcher::Storage.system_info.cached_info
      #   Dbwatcher::Storage.system_info.refresh_info
      def system_info
        @system_info ||= SystemInfoStorage.new
      end

      # Resets all cached storage instances (primarily for testing)
      #
      # This method clears all memoized storage instances, forcing them
      # to be recreated on next access. Useful for testing scenarios.
      #
      # @return [void]
      # @example
      #   Dbwatcher::Storage.reset_storage_instances!
      def reset_storage_instances!
        @session_storage = nil
        @query_storage = nil
        @table_storage = nil
        @system_info = nil
        @sessions = nil
        @queries = nil
        @tables = nil
      end

      # Cleanup operations

      # Removes old session files based on configuration
      #
      # Automatically removes session files that exceed the configured
      # retention period. This helps manage storage space usage.
      #
      # @return [void]
      # @see Configuration#auto_clean_after_days
      def cleanup_old_sessions
        session_storage.cleanup_old_sessions
      end

      # Direct access to storage instances (for internal use)

      # Returns the session storage instance
      #
      # @return [SessionStorage] the session storage instance
      # @api private
      def session_storage
        @session_storage ||= SessionStorage.new
      end

      # Returns the query storage instance
      #
      # @return [QueryStorage] the query storage instance
      # @api private
      def query_storage
        @query_storage ||= QueryStorage.new
      end

      # Returns the table storage instance
      #
      # @return [TableStorage] the table storage instance
      # @api private
      def table_storage
        @table_storage ||= TableStorage.new(session_storage)
      end

      # Clears all storage data
      #
      # @return [Integer] total number of files removed
      def clear_all
        session_count = session_storage.clear_all
        query_count = query_storage.clear_all
        session_count + query_count
      end
    end
  end
end
