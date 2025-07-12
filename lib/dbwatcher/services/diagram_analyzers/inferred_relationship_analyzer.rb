# frozen_string_literal: true

require "active_support/core_ext/string/inflections" if defined?(ActiveSupport)

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Analyzes relationships based on naming conventions and data patterns
      #
      # This service infers relationships between tables when explicit foreign keys
      # are not present, using naming conventions, column patterns, and junction table detection.
      #
      # @example
      #   analyzer = InferredRelationshipAnalyzer.new(session)
      #   dataset = analyzer.call
      class InferredRelationshipAnalyzer < BaseAnalyzer
        # Initialize with session
        #
        # @param session [Session] session to analyze (optional for global analysis)
        def initialize(session = nil)
          @session = session
          @connection = ActiveRecord::Base.connection if defined?(ActiveRecord::Base)
          @session_tables = session ? extract_session_tables : []
          super()
        end

        # Analyze inferred relationships
        #
        # @param context [Hash] analysis context
        # @return [Array<Hash>] array of inferred relationship data
        def analyze(_context)
          return [] unless schema_available?

          Rails.logger.debug "InferredRelationshipAnalyzer: Starting analysis with #{tables_to_analyze.length} tables"
          relationships = []

          # Analyze naming convention relationships
          relationships.concat(analyze_naming_conventions)

          # Analyze junction tables
          relationships.concat(analyze_junction_tables)

          # Analyze column patterns
          relationships.concat(analyze_column_patterns)

          Rails.logger.info "InferredRelationshipAnalyzer: Found #{relationships.length} inferred relationships"
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
                                    tables_analyzed: tables_to_analyze.length,
                                    inference_types: raw_data.map { |r| r[:inference_type] }.uniq
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
            entity = create_entity(
              id: table_name,
              name: table_name,
              type: "table",
              metadata: {
                table_name: table_name,
                source: "inferred_analysis"
              }
            )
            dataset.add_entity(entity)
            table_entities[table_name] = entity
          end

          # Create relationships in a separate loop
          raw_data.each do |relationship|
            next unless relationship[:from_table] && relationship[:to_table]

            # Include self-referential relationships (source and target are the same)
            # but log them for debugging
            if relationship[:from_table] == relationship[:to_table]
              Rails.logger.info "InferredRelationshipAnalyzer: Including self-referential relationship for " \
                                "#{relationship[:from_table]} " \
                                "(#{relationship[:from_column]} -> #{relationship[:to_column]})"
            end

            relationship_obj = create_relationship({
                                                     source_id: relationship[:from_table],
                                                     target_id: relationship[:to_table],
                                                     type: relationship[:type],
                                                     label: relationship[:label],
                                                     metadata: {
                                                       inference_type: relationship[:inference_type],
                                                       confidence: relationship[:confidence],
                                                       from_column: relationship[:from_column],
                                                       to_column: relationship[:to_column],
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
          "inferred_relationship"
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

        # Check if schema analysis is available
        #
        # @return [Boolean] true if schema can be analyzed
        def schema_available?
          defined?(ActiveRecord::Base) &&
            connection.respond_to?(:tables) &&
            connection.respond_to?(:columns)
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

        # Analyze naming convention relationships (e.g., user_id -> users)
        #
        # @return [Array<Hash>] naming convention relationships
        def analyze_naming_conventions
          relationships = []

          tables_to_analyze.each do |table_name|
            next unless table_exists?(table_name)

            columns = get_table_columns(table_name)

            columns.each do |column|
              # Look for _id columns that might reference other tables
              next unless column.name.end_with?("_id") && column.name != "id"

              # Check for common self-referential patterns
              if self_referential_column?(column.name, table_name)
                relationships << {
                  from_table: table_name,
                  to_table: table_name,
                  type: "inferred_belongs_to",
                  inference_type: "self_referential",
                  confidence: 0.9,
                  from_column: column.name,
                  to_column: "id",
                  label: "inferred (#{column.name})"
                }
                next
              end

              referenced_table = infer_table_from_column(column.name)

              next unless referenced_table && tables_to_analyze.include?(referenced_table)

              relationships << {
                from_table: table_name,
                to_table: referenced_table,
                type: "inferred_belongs_to",
                inference_type: "naming_convention",
                confidence: 0.8,
                from_column: column.name,
                to_column: "id",
                label: "inferred (#{column.name})"
              }
            end
          end

          relationships
        end

        # Check if a column name suggests a self-referential relationship
        #
        # @param column_name [String] column name to check
        # @param table_name [String] current table name
        # @param primary_key [String, nil] optional primary key for testing
        # @return [Boolean] true if likely self-referential
        def self_referential_column?(column_name, table_name, primary_key = nil)
          # Common self-referential patterns
          self_ref_patterns = %w[
            parent_id
            ancestor_id
            child_id
            reply_to_id
            reference_id
            original_id
            source_id
            target_id
            superior_id
            manager_id
            supervisor_id
            predecessor_id
            successor_id
            previous_id
            next_id
            related_id
            duplicate_id
            clone_id
            copy_id
            forwarded_id
            replied_to_id
          ]

          # Check if column is in the common self-referential patterns
          return true if self_ref_patterns.include?(column_name)

          # Get the singular form of the table name
          singular_table = singularize(table_name)

          # Special case for post_id in posts table - not a self-reference
          return false if column_name == "#{singular_table}_id" && table_name == "posts" && singular_table == "post"

          # Check for table-specific self-references (e.g., comment_id in comments table)
          if column_name == "#{singular_table}_id"
            # Check if this is not the primary key column
            if primary_key.nil?
              begin
                primary_key = connection.primary_key(table_name)
              rescue StandardError
                return false
              end
            end

            return column_name != primary_key
          end

          # Check for hierarchy patterns with table name
          hierarchy_prefixes = %w[parent child ancestor descendant superior subordinate manager supervisor]
          hierarchy_prefixes.each do |prefix|
            # Check for patterns like parent_node_id in nodes table
            return true if column_name.start_with?("#{prefix}_#{singular_table}_id")

            # Check for patterns like parent_of_id in any table
            return true if column_name.start_with?("#{prefix}_of_id")
          end

          # Check for relationship patterns
          relationship_patterns = %w[related linked connected associated referenced]
          relationship_patterns.each do |pattern|
            return true if column_name.start_with?("#{pattern}_")
          end

          # Check for directional patterns
          directional_patterns = %w[previous next original copy source target]
          directional_patterns.each do |pattern|
            return true if column_name.start_with?("#{pattern}_")
          end

          # Check for primary key reference (if provided)
          if primary_key && column_name.end_with?("_#{primary_key}")
            base_name = column_name.gsub(/_#{primary_key}$/, "")
            return true if base_name == singular_table
          end

          # Not self-referential
          false
        end

        # Analyze junction tables (many-to-many relationships)
        #
        # @return [Array<Hash>] junction table relationships
        def analyze_junction_tables
          relationships = []

          tables_to_analyze.each do |table_name|
            next unless junction_table?(table_name)

            junction_relationships = analyze_junction_table(table_name)
            relationships.concat(junction_relationships)
          end

          relationships
        end

        # Analyze column patterns for relationships
        #
        # @return [Array<Hash>] column pattern relationships
        def analyze_column_patterns
          relationships = []

          # Look for common patterns like created_by_id, updated_by_id, etc.
          tables_to_analyze.each do |table_name|
            next unless table_exists?(table_name)

            columns = get_table_columns(table_name)

            columns.each do |column|
              # Look for audit columns that might reference users
              next unless audit_column?(column.name)

              user_table = find_user_table

              next unless user_table && tables_to_analyze.include?(user_table)

              relationships << {
                from_table: table_name,
                to_table: user_table,
                type: "inferred_audit",
                inference_type: "audit_pattern",
                confidence: 0.6,
                from_column: column.name,
                to_column: "id",
                label: "audit (#{column.name})"
              }
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

        # Get columns for a table
        #
        # @param table_name [String] table name
        # @return [Array] column objects
        def get_table_columns(table_name)
          connection.columns(table_name)
        rescue StandardError => e
          Rails.logger.warn "InferredRelationshipAnalyzer: Could not get columns for #{table_name}: #{e.message}"
          []
        end

        # Infer table name from column name (e.g., user_id -> users)
        #
        # @param column_name [String] column name ending with _id
        # @return [String, nil] inferred table name
        def infer_table_from_column(column_name)
          base_name = column_name.gsub(/_id$/, "")

          # Try pluralized version first
          plural_table = pluralize(base_name)
          return plural_table if connection.table_exists?(plural_table)

          # Try singular version
          return base_name if connection.table_exists?(base_name)

          nil
        end

        # Get the plural form of a table name
        #
        # @param table_name [String] table name
        # @return [String] plural form of table name
        def pluralize(table_name)
          return table_name if table_name.nil? || table_name.empty?

          # Use ActiveSupport if available
          return table_name.pluralize if table_name.respond_to?(:pluralize)

          # Simple fallback pluralization rules
          if table_name.end_with?("y") && !table_name.end_with?("ay", "ey", "iy", "oy", "uy")
            "#{table_name[0...-1]}ies"
          elsif table_name.end_with?("s", "x", "z", "ch", "sh")
            "#{table_name}es"
          else
            "#{table_name}s"
          end
        end

        # Check if table is likely a junction table
        #
        # @param table_name [String] table name
        # @return [Boolean] true if likely junction table
        def junction_table?(table_name)
          # Common junction table patterns
          return true if table_name.include?("_")

          columns = get_table_columns(table_name)
          id_columns = columns.select { |c| c.name.end_with?("_id") && c.name != "id" }

          # Junction tables typically have 2+ foreign key columns and few other columns
          id_columns.length >= 2 && columns.length <= (id_columns.length + 3)
        end

        # Analyze a junction table for relationships
        #
        # @param table_name [String] junction table name
        # @return [Array<Hash>] junction relationships
        def analyze_junction_table(table_name)
          relationships = []
          columns = get_table_columns(table_name)
          id_columns = columns.select { |c| c.name.end_with?("_id") && c.name != "id" }

          # Create many-to-many relationships between the referenced tables
          id_columns.combination(2).each do |col1, col2|
            table1 = infer_table_from_column(col1.name)
            table2 = infer_table_from_column(col2.name)

            next unless table1 && table2 && tables_to_analyze.include?(table1) && tables_to_analyze.include?(table2)

            relationships << {
              from_table: table1,
              to_table: table2,
              type: "inferred_many_to_many",
              inference_type: "junction_table",
              confidence: 0.9,
              from_column: "id",
              to_column: "id",
              label: "many-to-many via #{table_name}"
            }
          end

          relationships
        end

        # Check if column is an audit column
        #
        # @param column_name [String] column name
        # @return [Boolean] true if audit column
        def audit_column?(column_name)
          %w[created_by_id updated_by_id deleted_by_id author_id modifier_id].include?(column_name)
        end

        # Find the user table in available tables
        #
        # @return [String, nil] user table name
        def find_user_table
          user_tables = %w[users user accounts account people person]
          user_tables.find { |table| tables_to_analyze.include?(table) }
        end

        # Get the singular form of a table name
        #
        # @param table_name [String] table name
        # @return [String] singular form of table name
        def singularize(table_name)
          return table_name if table_name.nil? || table_name.empty?

          # Use ActiveSupport if available
          return table_name.singularize if table_name.respond_to?(:singularize)

          # Simple fallback singularization rules
          if table_name.end_with?("ies")
            "#{table_name[0...-3]}y"
          elsif table_name.end_with?("s")
            table_name[0...-1]
          else
            table_name
          end
        end
      end
    end
  end
end
