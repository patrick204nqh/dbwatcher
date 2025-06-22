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
      class SchemaRelationshipAnalyzer < BaseAnalyzer
        # Initialize with session
        #
        # @param session [Session] session to analyze (optional for global analysis)
        def initialize(session = nil)
          @session = session
          @connection = ActiveRecord::Base.connection if defined?(ActiveRecord::Base)
          @session_tables = session ? extract_session_tables : []
          super()
        end

        # New standardized interface: analyze schema relationships
        #
        # @param context [Hash] analysis context
        # @return [Array<Hash>] array of relationship data
        def analyze(_context)
          return [] unless schema_available?

          Rails.logger.debug "SchemaRelationshipAnalyzer: Starting analysis with #{tables_to_analyze.length} tables"
          relationships = extract_foreign_key_relationships

          # Log some sample data to help with debugging
          if relationships.any?
            sample_relationship = relationships.first
            Rails.logger.debug "SchemaRelationshipAnalyzer: Sample relationship - " \
                               "from_table: #{sample_relationship[:from_table]}, " \
                               "to_table: #{sample_relationship[:to_table]}, " \
                               "type: #{sample_relationship[:type]}"
          else
            Rails.logger.info "SchemaRelationshipAnalyzer: No relationships found"
          end

          relationships
        end

        # Transform raw relationship data to DiagramDataset
        #
        # @param raw_data [Array<Hash>] raw relationship data
        # @return [DiagramData::DiagramDataset] standardized dataset
        def transform_to_dataset(raw_data)
          dataset = create_empty_dataset
          dataset.metadata.merge!({
                                    analyzer_type: "schema_relationships",
                                    total_relationships: raw_data.length,
                                    tables_analyzed: tables_to_analyze.length
                                  })

          # Create entities for each unique table
          table_entities = {}
          raw_data.each do |relationship|
            # Create source entity
            if relationship[:from_table] && !table_entities.key?(relationship[:from_table])
              entity = create_entity(
                id: relationship[:from_table],
                name: relationship[:from_table],
                type: "table",
                metadata: {
                  table_name: relationship[:from_table],
                  source: "database_schema"
                }
              )
              dataset.add_entity(entity)
              table_entities[relationship[:from_table]] = entity
            end

            # Create target entity
            next unless relationship[:to_table] && !table_entities.key?(relationship[:to_table])

            entity = create_entity(
              id: relationship[:to_table],
              name: relationship[:to_table],
              type: "table",
              metadata: {
                table_name: relationship[:to_table],
                source: "database_schema"
              }
            )
            dataset.add_entity(entity)
            table_entities[relationship[:to_table]] = entity
          end

          # Create relationships
          raw_data.each do |relationship|
            next unless relationship[:from_table] && relationship[:to_table]

            # Skip self-referential relationships (source and target are the same)
            if relationship[:from_table] == relationship[:to_table]
              Rails.logger.info "SchemaRelationshipAnalyzer: Skipping self-referential relationship for #{relationship[:from_table]}"
              next
            end

            relationship_obj = create_relationship(
              source_id: relationship[:from_table],
              target_id: relationship[:to_table],
              type: relationship[:type],
              label: relationship[:constraint_name],
              metadata: {
                constraint_name: relationship[:constraint_name],
                from_column: relationship[:from_column],
                to_column: relationship[:to_column],
                on_delete: relationship[:on_delete],
                on_update: relationship[:on_update],
                original_type: relationship[:type]
              }
            )

            dataset.add_relationship(relationship_obj)
          end

          dataset
        end

        # Analyzer capabilities
        #
        # @return [Array<Symbol>] capabilities
        def capabilities
          %i[schema_relationships foreign_keys database_constraints]
        end

        private

        attr_reader :session, :connection, :session_tables

        # Check if schema analysis is available
        #
        # @return [Boolean] true if schema can be analyzed
        def schema_available?
          defined?(ActiveRecord::Base) &&
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

        # Abstract method implementations for BaseAnalyzer

        # Get analyzer name
        #
        # @return [String] human-readable analyzer name
        def analyzer_name
          "Schema Relationship Analyzer"
        end

        # Get analyzer description
        #
        # @return [String] analyzer description
        def analyzer_description
          "Analyzes database schema to detect foreign key relationships between tables"
        end
      end
    end
  end
end
