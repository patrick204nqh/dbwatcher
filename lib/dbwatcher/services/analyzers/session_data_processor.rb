# frozen_string_literal: true

module Dbwatcher
  module Services
    module Analyzers
      # Handles session data processing and change iteration
      #
      # This service extracts and processes individual changes from session data,
      # providing a clean interface for iterating over table changes.
      #
      # @example
      #   processor = SessionDataProcessor.new(session)
      #   processor.process_changes do |table_name, change, tables|
      #     # Process each change
      #   end
      class SessionDataProcessor < BaseService
        # Initialize with session
        #
        # @param session [Session] session to process
        def initialize(session)
          @session = session
          super()
        end

        # Process all changes in the session
        #
        # @return [Hash] tables hash with processed data
        def call
          log_service_start "Processing session changes", session_context
          start_time = Time.current

          tables = {}

          process_changes do |table_name, change, tables_ref|
            yield(table_name, change, tables_ref) if block_given?
          end

          log_service_completion(start_time, { tables_found: tables.keys.length })
          tables
        end

        # Process changes with block
        #
        # @yield [table_name, change, tables] for each change
        # @return [Hash] tables hash
        def process_changes
          return {} unless session&.changes.respond_to?(:each)

          tables = {}

          session.changes.each do |change|
            table_name = extract_table_name(change)
            next unless table_name

            yield(table_name, change, tables) if block_given?
          end

          tables
        end

        # Extract table name from change data
        #
        # @param change [Hash] change data
        # @return [String, nil] table name or nil
        def extract_table_name(change)
          return nil unless change.is_a?(Hash)

          change[:table_name]
        end

        # Extract session tables that were modified
        #
        # @return [Array<String>] unique table names
        def extract_session_tables
          return [] unless session&.changes

          session.changes.map do |change|
            extract_table_name(change)
          end.compact.uniq
        end

        private

        attr_reader :session

        # Build context for logging
        #
        # @return [Hash] session context
        def session_context
          {
            session_id: session&.id,
            changes_count: session&.changes&.count || 0
          }
        end
      end
    end
  end
end
