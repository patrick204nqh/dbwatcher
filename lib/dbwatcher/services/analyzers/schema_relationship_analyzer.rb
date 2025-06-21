# frozen_string_literal: true

module Dbwatcher
  module Services
    module Analyzers
      # Analyzes relationships based on database schema foreign keys
      #
      # This service examines the actual database schema to detect foreign key
      # relationships between tables that were involved in a session.
      #
      # @example
      #   analyzer = SchemaRelationshipAnalyzer.new(session)
      #   relationships = analyzer.call
      #   # => [{ from_table: "orders", to_table: "users", constraint_name: "fk_orders_user_id" }]
      class SchemaRelationshipAnalyzer < BaseService
        # Initialize with session
        #
        # @param session [Session] session to analyze (optional for global analysis)
        def initialize(session = nil)
          @session = session
          @connection = ActiveRecord::Base.connection if defined?(ActiveRecord::Base)
          @session_tables = session ? extract_session_tables : []
          super()
        end

        # Analyze schema relationships
        #
        # @return [Array<Hash>] array of relationship data
        def call
          return [] unless schema_available?

          log_service_start "Analyzing schema relationships", analysis_context
          start_time = Time.current

          relationships = extract_foreign_key_relationships

          log_service_completion(start_time, {
                                   relationships_found: relationships.length,
                                   tables_analyzed: tables_to_analyze.length
                                 })

          relationships
        end

        private

        attr_reader :session, :connection, :session_tables

        # Check if schema analysis is available
        #
        # @return [Boolean] true if schema can be analyzed
        def schema_available?
          defined?(ActiveRecord::Base) &&
            connection &&
            connection.respond_to?(:foreign_keys) &&
            connection.respond_to?(:tables)
        end

        # Extract tables that were involved in the session
        #
        # @return [Array<String>] unique table names
        def extract_session_tables
          return [] unless session&.changes

          session.changes.map do |change|
            change[:table_name] || change["table_name"]
          end.compact.uniq
        end

        # Get tables to analyze (session tables or all tables if no session)
        #
        # @return [Array<String>] table names to analyze
        def tables_to_analyze
          session_tables.any? ? session_tables : connection.tables
        end

        # Extract foreign key relationships from schema
        #
        # @return [Array<Hash>] relationships array
        def extract_foreign_key_relationships
          relationships = []

          tables_to_analyze.each do |table_name|
            next unless table_exists?(table_name)

            foreign_keys = get_foreign_keys(table_name)

            foreign_keys.each do |fk|
              # Only include if target table is also in scope
              relationships << build_schema_relationship(table_name, fk) if target_table_in_scope?(fk.to_table)
            end
          end

          relationships
        end

        # Check if table exists in database
        #
        # @param table_name [String] table name
        # @return [Boolean] true if table exists
        def table_exists?(table_name)
          connection.table_exists?(table_name)
        rescue StandardError
          false
        end

        # Get foreign keys for a table
        #
        # @param table_name [String] table name
        # @return [Array] foreign key objects
        def get_foreign_keys(table_name)
          connection.foreign_keys(table_name)
        rescue StandardError
          []
        end

        # Check if target table is in analysis scope
        #
        # @param target_table [String] target table name
        # @return [Boolean] true if target should be included
        def target_table_in_scope?(target_table)
          # If analyzing session, both tables must be in session
          # If analyzing globally, include all
          session_tables.empty? || session_tables.include?(target_table)
        end

        # Build relationship data from foreign key
        #
        # @param table_name [String] source table name
        # @param foreign_key [Object] foreign key object
        # @return [Hash] relationship data
        def build_schema_relationship(table_name, foreign_key)
          {
            type: "schema_foreign_key",
            from_table: table_name,
            to_table: foreign_key.to_table,
            from_column: foreign_key.column,
            to_column: foreign_key.primary_key || "id",
            constraint_name: foreign_key.name,
            on_delete: foreign_key.on_delete,
            on_update: foreign_key.on_update
          }
        end

        # Build context for logging
        #
        # @return [Hash] analysis context
        def analysis_context
          {
            session_id: session&.id,
            session_tables_count: session_tables.length,
            total_db_tables: connection&.tables&.length || 0,
            analyzing_scope: session_tables.any? ? "session" : "global"
          }
        end
      end
    end
  end
end
