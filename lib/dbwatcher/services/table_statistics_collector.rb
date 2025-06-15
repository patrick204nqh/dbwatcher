# frozen_string_literal: true

module Dbwatcher
  module Services
    # Service object for collecting and organizing table statistics
    # Follows the command pattern with self.call class method
    class TableStatisticsCollector
      include Dbwatcher::Logging

      # @return [Array<Hash>] sorted array of table statistics
      def self.call
        new.call
      end

      def call
        log_info "Starting table statistics collection"
        start_time = Time.current

        tables = build_initial_tables_hash
        populate_change_statistics(tables)
        result = sort_by_change_count(tables)

        duration = Time.current - start_time
        log_info "Completed table statistics collection in #{duration.round(3)}s", {
          tables_count: result.length,
          total_changes: result.sum { |t| t[:change_count] }
        }

        result
      end

      private

      def build_initial_tables_hash
        tables = {}
        schema_tables_count = load_schema_tables(tables)
        log_schema_loading_result(schema_tables_count)
        tables
      end

      def load_schema_tables(tables)
        return 0 unless schema_available?

        schema_tables_count = 0
        begin
          ActiveRecord::Base.connection.tables.each do |table|
            tables[table] = build_table_entry(table)
            schema_tables_count += 1
          end
          schema_tables_count
        rescue StandardError => e
          log_warn "Could not load tables from schema: #{e.message}"
          0
        end
      end

      def schema_available?
        defined?(ActiveRecord::Base)
      end

      def log_schema_loading_result(count)
        if count.positive?
          log_debug "Loaded #{count} tables from database schema"
        else
          log_debug "ActiveRecord not available, starting with empty tables hash"
        end
      end

      def build_table_entry(table_name)
        {
          name: table_name,
          change_count: 0,
          last_change: nil
        }
      end

      def populate_change_statistics(tables)
        sessions_processed = 0
        total_changes = 0

        Storage.sessions.all.each do |session_info|
          session = Storage.sessions.find(session_info[:id])
          next unless session

          session_changes_count = session.changes.length
          update_tables_from_session(tables, session)
          sessions_processed += 1
          total_changes += session_changes_count
        end

        log_debug "Processed #{sessions_processed} sessions with #{total_changes} total changes"
        tables
      end

      def update_tables_from_session(tables, session)
        session.changes.each do |change|
          table_name = change[:table_name]
          next if table_name.nil? || table_name.empty?

          tables[table_name] ||= build_table_entry(table_name)
          update_table_change_statistics(tables[table_name], change)
        end
      end

      def update_table_change_statistics(table_stats, change)
        table_stats[:change_count] += 1
        timestamp = change[:timestamp]

        return unless table_stats[:last_change].nil? || timestamp > table_stats[:last_change]

        table_stats[:last_change] = timestamp
      end

      def sort_by_change_count(tables)
        tables.values.sort_by { |table| -table[:change_count] }
      end
    end
  end
end
