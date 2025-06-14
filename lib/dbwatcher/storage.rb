# frozen_string_literal: true

require_relative 'storage/base'
require_relative 'storage/session_storage'
require_relative 'storage/query_storage'
require_relative 'storage/table_storage'

module Dbwatcher
  module Storage
    class << self
      def session_storage
        @session_storage ||= SessionStorage.new
      end

      def query_storage
        @query_storage ||= QueryStorage.new
      end

      def table_storage
        @table_storage ||= TableStorage.new(session_storage)
      end

      # Reset cached storage instances (for testing)
      def reset_storage_instances!
        @session_storage = nil
        @query_storage = nil
        @table_storage = nil
      end

      # Session methods - delegate to SessionStorage
      def save_session(session)
        session_storage.save(session)
      rescue StandardError => e
        warn "Failed to save session #{session&.id}: #{e.message}"
      end

      def load_session(id)
        session_storage.load(id)
      end

      def all_sessions
        session_storage.all
      end

      def reset!
        session_storage.reset!
      end

      # Query methods - delegate to QueryStorage
      def save_query(query)
        query_storage.save(query)
      end

      def load_queries_for_date(date)
        query_storage.load_for_date(date)
      end

      # Table methods - delegate to TableStorage
      def load_table_changes(table_name)
        table_storage.load_changes(table_name)
      rescue StandardError => e
        warn "Failed to load table changes for #{table_name}: #{e.message}"
        []
      end

      # Cleanup methods
      def cleanup_old_sessions
        session_storage.cleanup_old_sessions
      end
    end
  end
end
