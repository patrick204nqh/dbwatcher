# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Analyzes relationships based on database schema foreign keys
      #
      # This service examines the actual database schema to detect foreign key
      # relationships between tables that were involved in a session.
      #
      # @example
      #   analyzer = ForeignKeyAnalyzer.new(session)
      #   dataset = analyzer.call
      class ForeignKeyAnalyzer < BaseAnalyzer
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
        # @param context [Hash] analysis context
        # @return [Array<Hash>] array of relationship data
        def analyze(_context)
          return [] unless schema_available?

          Rails.logger.debug "ForeignKeyAnalyzer: Starting analysis with #{tables_to_analyze.length} tables"
          relationships = extract_foreign_key_relationships

          # Log some sample data to help with debugging
          if relationships.any?
            sample_relationship = relationships.first
            Rails.logger.debug "ForeignKeyAnalyzer: Sample relationship - " \
                               "from_table: #{sample_relationship[:from_table]}, " \
                               "to_table: #{sample_relationship[:to_table]}, " \
                               "type: #{sample_relationship[:type]}"
          else
            Rails.logger.info "ForeignKeyAnalyzer: No relationships found"
          end

          relationships
        end

        # Transform raw relationship data to Dataset
        #
        # @param raw_data [Array<Hash>] raw relationship data
        # @return [DiagramData::Dataset] standardized dataset
        def transform_to_dataset(raw_data)
          dataset = create_empty_dataset
          dataset.metadata.merge!({
                                    total_relationships: raw_data.length,
                                    tables_analyzed: tables_to_analyze.length
                                  })

          # Create entities for each unique table
          table_entities = {}

          # First, collect all unique tables from the relationships
          tables = []
          raw_data.each do |relationship|
            tables << relationship[:from_table] if relationship[:from_table]
            tables << relationship[:to_table] if relationship[:to_table]
          end
          tables.uniq!

          # Create entities for all tables
          tables.each do |table_name|
            entity = create_entity_with_columns(table_name)
            dataset.add_entity(entity)
            table_entities[table_name] = entity
          end

          # Create relationships in a separate loop
          raw_data.each do |relationship|
            next unless relationship[:from_table] && relationship[:to_table]

            # Include self-referential relationships (source and target are the same)
            # but log them for debugging
            if relationship[:from_table] == relationship[:to_table]
              Rails.logger.info "ForeignKeyAnalyzer: Including self-referential relationship for " \
                                "#{relationship[:from_table]} " \
                                "(#{relationship[:from_column]} -> #{relationship[:to_column]})"
            end

            cardinality = determine_cardinality(relationship)

            relationship_obj = create_relationship({
                                                     source_id: relationship[:from_table],
                                                     target_id: relationship[:to_table],
                                                     type: relationship[:type],
                                                     label: relationship[:constraint_name] ||
                    relationship[:from_column],
                                                     cardinality: cardinality,
                                                     metadata: {
                                                       constraint_name: relationship[:constraint_name],
                                                       from_column: relationship[:from_column],
                                                       to_column: relationship[:to_column],
                                                       on_delete: relationship[:on_delete],
                                                       on_update: relationship[:on_update],
                                                       original_type: relationship[:type],
                                                       self_referential: relationship[:from_table] ==
                                  relationship[:to_table]
                                                     }
                                                   })

            dataset.add_relationship(relationship_obj)
          end

          dataset
        end

        # Get analyzer type
        #
        # @return [String] analyzer type identifier
        def analyzer_type
          "foreign_key"
        end

        protected

        # Build analysis context for this analyzer
        #
        # @return [Hash] analysis context
        def analysis_context
          {
            session: session,
            session_tables: session_tables,
            tables_to_analyze: tables_to_analyze
          }
        end

        # Get the database connection
        #
        # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] database connection
        attr_reader :connection

        private

        attr_reader :session, :session_tables

        # Create entity with table columns
        #
        # @param table_name [String] table name
        # @return [DiagramData::Entity] entity with columns as attributes
        def create_entity_with_columns(table_name)
          return nil unless table_exists?(table_name)

          attributes = []

          # Extract columns from table
          if connection.respond_to?(:columns)
            begin
              columns = connection.columns(table_name)

              # Convert columns to attributes
              attributes = columns.map do |column|
                primary_key = column.name == connection.primary_key(table_name)
                foreign_key = column.name.end_with?("_id") ||
                              foreign_key_columns(table_name).include?(column.name)

                create_attribute(
                  name: column.name,
                  type: column.type.to_s,
                  nullable: column.null,
                  default: column.default,
                  metadata: {
                    primary_key: primary_key,
                    foreign_key: foreign_key,
                    limit: column.limit,
                    precision: column.precision,
                    scale: column.scale,
                    visibility: "+" # Public visibility for all columns
                  }
                )
              end
            rescue StandardError => e
              Rails.logger.warn "ForeignKeyAnalyzer: Could not get columns for #{table_name}: #{e.message}"
            end
          end

          create_entity(
            id: table_name,
            name: table_name,
            type: "table",
            attributes: attributes,
            metadata: {
              table_name: table_name,
              source: "database_schema"
            }
          )
        end

        # Get foreign key column names for a table
        #
        # @param table_name [String] table name
        # @return [Array<String>] foreign key column names
        def foreign_key_columns(table_name)
          return [] unless connection.respond_to?(:foreign_keys)

          begin
            connection.foreign_keys(table_name).map(&:column)
          rescue StandardError => e
            Rails.logger.warn "ForeignKeyAnalyzer: Could not get foreign keys for #{table_name}: #{e.message}"
            []
          end
        end

        # Determine relationship cardinality
        #
        # @param relationship [Hash] relationship data
        # @return [String] cardinality type
        def determine_cardinality(relationship)
          # For foreign keys, we can determine cardinality based on constraints
          if relationship[:from_column] && relationship[:to_column]
            # If the foreign key column is part of a unique constraint or primary key,
            # it's likely a one-to-one relationship
            return "one_to_one" if column_has_unique_constraint?(relationship[:from_table], relationship[:from_column])

            # Default to one-to-many for standard foreign keys
            # (many records in source table can reference one record in target table)
            return "many_to_one"
          end

          # Default to one-to-many if we can't determine
          "one_to_many"
        end

        # Check if column has a unique constraint
        #
        # @param table_name [String] table name
        # @param column_name [String] column name
        # @return [Boolean] true if column has unique constraint
        def column_has_unique_constraint?(table_name, column_name)
          # Check if column is primary key
          return true if column_name == connection.primary_key(table_name)

          # Check for unique indexes if supported
          if connection.respond_to?(:indexes)
            begin
              indexes = connection.indexes(table_name)
              return indexes.any? { |idx| idx.columns == [column_name] && idx.unique }
            rescue StandardError => e
              Rails.logger.warn "ForeignKeyAnalyzer: Could not check unique constraints for " \
                                "#{table_name}.#{column_name}: #{e.message}"
            end
          end

          false
        end

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
        rescue StandardError => e
          Rails.logger.warn "ForeignKeyAnalyzer: Could not get foreign keys for #{table_name}: #{e.message}"
          []
        end

        # Check if target table is in analysis scope
        #
        # @param target_table [String] target table name
        # @return [Boolean] true if target table should be included
        def target_table_in_scope?(target_table)
          # If analyzing session, both tables must be in session
          # If analyzing globally, include all
          session_tables.empty? || session_tables.include?(target_table)
        end

        # Build relationship hash from foreign key
        #
        # @param table_name [String] source table name
        # @param foreign_key [Object] foreign key object
        # @return [Hash] relationship data
        def build_schema_relationship(table_name, foreign_key)
          {
            from_table: table_name,
            to_table: foreign_key.to_table,
            type: "foreign_key",
            constraint_name: foreign_key.name,
            from_column: foreign_key.column,
            to_column: foreign_key.primary_key,
            on_delete: foreign_key.on_delete,
            on_update: foreign_key.on_update
          }
        end
      end
    end
  end
end
