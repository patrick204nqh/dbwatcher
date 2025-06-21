# frozen_string_literal: true

require "set"

module Dbwatcher
  module Services
    module Analyzers
      # Builds comprehensive table summaries from session data
      #
      # This service aggregates table operations, captures sample records,
      # and builds complete table summaries for analysis and visualization.
      #
      # @example
      #   builder = TableSummaryBuilder.new(session)
      #   summary = builder.call
      #   # => { "users" => { columns: Set, sample_record: {}, operations: {}, changes: [] } }
      class TableSummaryBuilder < BaseService
        # Initialize with session
        #
        # @param session [Session] session to analyze
        def initialize(session)
          super()
          @session = session
          @processor = SessionDataProcessor.new(session)
        end

        # Build table summaries from session data
        #
        # @return [Hash] table summaries keyed by table name
        def call
          log_service_start("session_id=#{session.id} changes_count=#{session.changes.length}")

          start_time = Time.now

          tables = {}

          processor.process_changes do |table_name, change, _tables|
            initialize_table_data(tables, table_name)
            update_table_data(tables[table_name], change)
            update_sample_record(tables[table_name], change)
          end

          # Filter out tables with no operations
          tables.reject! { |_, data| data[:total_operations].zero? }

          # Convert operation counts to string keys for view compatibility
          tables.each do |_, data|
            data[:operations] = {
              "INSERT" => data[:operations][:insert] || 0,
              "UPDATE" => data[:operations][:update] || 0,
              "DELETE" => data[:operations][:delete] || 0
            }

            # Remove operations with zero count
            data[:operations].reject! { |_, count| count.zero? }
          end

          result_context = {
            tables_analyzed: tables.keys.length,
            total_operations: tables.values.sum { |t| t[:total_operations] }
          }

          log_service_completion(start_time, result_context)
          tables
        end

        private

        attr_reader :session, :processor

        # Initialize table data structure
        #
        # @param tables [Hash] tables collection
        # @param table_name [String] table name
        def initialize_table_data(tables, table_name)
          tables[table_name] ||= {
            name: table_name,
            columns: Set.new,
            sample_record: nil,
            total_operations: 0,
            operations: { insert: 0, update: 0, delete: 0 },
            changes: []
          }
        end

        # Update table data with change information
        #
        # @param table_data [Hash] table data structure
        # @param change [Hash] change data
        def update_table_data(table_data, change)
          # Extract and normalize operation
          operation = extract_operation(change)

          # Update counters
          table_data[:total_operations] += 1
          table_data[:operations][operation] = table_data[:operations].fetch(operation, 0) + 1

          # Add the actual change data for view display
          table_data[:changes] << change
        end

        # Update sample record to capture all columns
        #
        # @param table_data [Hash] table data structure
        # @param change [Hash] change data
        def update_sample_record(table_data, change)
          # Try multiple possible data sources for record snapshot
          sample_data = extract_record_data(change)
          return unless sample_data.is_a?(Hash)

          # Initialize or merge sample record
          if table_data[:sample_record].nil?
            table_data[:sample_record] = sample_data.dup
          else
            # Merge to capture all possible columns from different records
            table_data[:sample_record].merge!(sample_data)
          end

          # Track all columns seen in this table
          sample_data.keys.each { |key| table_data[:columns].add(key.to_s) }
        end

        # Extract operation type from change data
        #
        # @param change [Hash] change data
        # @return [Symbol] operation type (:insert, :update, :delete)
        def extract_operation(change)
          operation_str = change[:operation]&.to_s&.downcase

          case operation_str
          when "insert" then :insert
          when "update" then :update
          when "delete" then :delete
          else
            log_warning("Unknown operation type: #{operation_str || "nil"}")
            :unknown
          end
        end

        # Log a warning message
        #
        # @param message [String] warning message
        def log_warning(message)
          puts "[WARNING] #{service_name}: #{message}"
        end

        # Extract record data from various change formats
        #
        # @param change [Hash] change data
        # @return [Hash, nil] record data or nil
        def extract_record_data(change)
          # Try record_snapshot first (most reliable)
          return change[:record_snapshot] if change[:record_snapshot].is_a?(Hash)

          # Fallback to building from changes array
          build_record_from_changes(change[:changes]) if change[:changes].is_a?(Array)
        end

        # Build record data from changes array
        #
        # @param changes [Array] array of column changes
        # @return [Hash] constructed record data
        def build_record_from_changes(changes)
          record = {}

          changes.each do |column_change|
            next unless column_change.is_a?(Hash) && column_change[:column]

            # Use new_value if available, otherwise old_value
            value = column_change[:new_value] || column_change[:old_value]
            record[column_change[:column]] = value
          end

          record
        end

        # Get service name for logging
        #
        # @return [String] service name
        def service_name
          "TableSummaryBuilder"
        end
      end
    end
  end
end
