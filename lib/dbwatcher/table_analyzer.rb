# frozen_string_literal: true

module Dbwatcher
  class TableAnalyzer
    def self.analyze_session(session_id)
      session = Storage.load_session(session_id)
      return {} unless session

      analyze_session_changes(session)
    end

    def self.analyze_session_changes(session)
      tables = {}

      session.changes.each do |change|
        table_name = extract_table_name(change)
        initialize_table_data(tables, table_name)
        process_change(tables, table_name, change)
      end

      tables
    end

    def self.extract_table_name(change)
      change["table_name"] || change[:table_name]
    end

    def self.initialize_table_data(tables, table_name)
      tables[table_name] ||= {
        name: table_name,
        operations: { "INSERT" => 0, "UPDATE" => 0, "DELETE" => 0 },
        records: {},
        relationships: []
      }
    end

    def self.process_change(tables, table_name, change)
      update_operation_count(tables, table_name, change)
      update_record_history(tables, table_name, change)
      detect_relationships(tables, table_name, change)
    end

    def self.update_operation_count(tables, table_name, change)
      operation = change["operation"] || change[:operation]
      tables[table_name][:operations][operation] += 1
    end

    def self.update_record_history(tables, table_name, change)
      record_id = change["record_id"] || change[:record_id]
      tables[table_name][:records][record_id] ||= []
      tables[table_name][:records][record_id] << change
    end

    def self.detect_relationships(tables, table_name, change)
      changes_array = change["changes"] || change[:changes] || []

      changes_array.each do |field_change|
        add_relationship_if_foreign_key(tables, table_name, field_change)
      end
    end

    def self.add_relationship_if_foreign_key(tables, table_name, field_change)
      column = field_change["column"] || field_change[:column]
      return unless column&.match?(/_id$/)

      related_table = column.gsub(/_id$/, "").pluralize
      return unless table_exists?(related_table)

      add_relationship_to_table(tables, table_name, related_table, column)
    end

    def self.add_relationship_to_table(tables, table_name, related_table, column)
      relationship = {
        from: table_name,
        to: related_table,
        column: column,
        type: "belongs_to"
      }

      return if tables[table_name][:relationships].include?(relationship)

      tables[table_name][:relationships] << relationship
    end

    def self.summarize_session(session_id)
      tables = analyze_session(session_id)
      create_summary_from_tables(tables)
    end

    def self.create_summary_from_tables(tables)
      summary = initialize_summary(tables)

      tables.each do |table_name, data|
        add_table_to_summary(summary, table_name, data)
        update_operation_totals(summary, data[:operations])
      end

      summary
    end

    def self.initialize_summary(tables)
      {
        total_tables: tables.count,
        total_operations: 0,
        operations_by_type: { "INSERT" => 0, "UPDATE" => 0, "DELETE" => 0 },
        tables_summary: {}
      }
    end

    def self.add_table_to_summary(summary, table_name, data)
      summary[:tables_summary][table_name] = {
        operations: data[:operations],
        record_count: data[:records].count,
        records: data[:records]
      }
    end

    def self.update_operation_totals(summary, operations)
      operations.each do |operation, count|
        summary[:total_operations] += count
        summary[:operations_by_type][operation] += count
      end
    end

    class << self
      private

      def table_exists?(table_name)
        return false unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.connection.table_exists?(table_name)
      rescue StandardError
        false
      end
    end
  end
end
