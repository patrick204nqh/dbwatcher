# frozen_string_literal: true

require_relative "storage/base"
require_relative "storage/session_storage"
require_relative "storage/query_storage"
require_relative "storage/table_storage"
require_relative "storage/session_query"
require_relative "storage/query_api"
require_relative "storage/table_api"
require_relative "storage/session"
require_relative "storage/errors"

module Dbwatcher
  module Storage
    class << self
      # Clean API entry points
      def sessions
        @session_query ||= SessionQuery.new(session_storage)
      end

      def queries
        @query_api ||= QueryAPI.new(query_storage)
      end

      def tables
        @table_api ||= TableAPI.new(table_storage)
      end

      # Reset cached storage instances (for testing)
      def reset_storage_instances!
        @session_storage = nil
        @query_storage = nil
        @table_storage = nil
        @session_query = nil
        @query_api = nil
        @table_api = nil
      end

      # Cleanup methods
      def cleanup_old_sessions
        session_storage.cleanup_old_sessions
      end

      # Direct access to storage instances (for internal use)
      def session_storage
        @session_storage ||= SessionStorage.new
      end

      def query_storage
        @query_storage ||= QueryStorage.new
      end

      def table_storage
        @table_storage ||= TableStorage.new(session_storage)
      end

      def reset!
        session_storage.reset!
      end
    end
  end
end
