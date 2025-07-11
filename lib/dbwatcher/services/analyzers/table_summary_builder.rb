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
          tables = build_tables_data
          log_service_completion(start_time, result_context(tables))
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
            changes: [],
            model_class: find_model_class(table_name)
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
          sample_data.each_key { |key| table_data[:columns].add(key.to_s) }
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

        # Build tables data by processing all changes
        def build_tables_data
          tables = {}

          processor.process_changes do |table_name, change, _tables|
            initialize_table_data(tables, table_name)
            update_table_data(tables[table_name], change)
            update_sample_record(tables[table_name], change)
          end

          filter_and_format_tables(tables)
        end

        # Filter out empty tables and format operations for view compatibility
        def filter_and_format_tables(tables)
          # Filter out tables with no operations
          tables.reject! { |_, data| data[:total_operations].zero? }

          # Convert operation counts to string keys for view compatibility
          tables.each_value do |data|
            data[:operations] = format_operations(data[:operations])
          end

          tables
        end

        # Format operations hash with string keys and remove zero counts
        def format_operations(operations)
          formatted = {
            "INSERT" => operations[:insert] || 0,
            "UPDATE" => operations[:update] || 0,
            "DELETE" => operations[:delete] || 0
          }
          formatted.reject { |_, count| count.zero? }
        end

        # Build result context for logging
        def result_context(tables)
          {
            tables_analyzed: tables.keys.length,
            total_operations: tables.values.sum { |t| t[:total_operations] }
          }
        end

        # Find the actual Rails model class for a table name
        #
        # @param table_name [String] database table name
        # @return [String, nil] model class name or nil if not found
        def find_model_class(table_name)
          return nil unless table_name.is_a?(String)

          Rails.logger.debug "Finding model class for table: #{table_name}"

          # Ensure all models are loaded
          Rails.application.eager_load! if Rails.env.development?

          # Try to find the model class by checking if it exists in Rails
          model_name = table_name.classify
          Rails.logger.debug "Expected model name: #{model_name}"
          
          # Check if the model class exists and is loaded
          if Object.const_defined?(model_name)
            model_class = Object.const_get(model_name)
            Rails.logger.debug "Found model class: #{model_class}"
            
            # Verify it's an ActiveRecord model and matches the table
            if model_class.respond_to?(:ancestors) && model_class.ancestors.include?(ActiveRecord::Base)
              if model_class.table_name == table_name
                Rails.logger.debug "Model #{model_class.name} matches table #{table_name}"
                return model_class.name
              else
                Rails.logger.debug "Model #{model_class.name} table_name (#{model_class.table_name}) doesn't match #{table_name}"
              end
            else
              Rails.logger.debug "#{model_class} is not an ActiveRecord model"
            end
          else
            Rails.logger.debug "Model class #{model_name} not found via const_defined"
          end

          # Try alternative approaches for namespaced models or different naming
          # Check all loaded ActiveRecord models
          Rails.logger.debug "Checking all ActiveRecord descendants..."
          ActiveRecord::Base.descendants.each do |model|
            if model.table_name == table_name
              Rails.logger.debug "Found matching model: #{model.name} for table #{table_name}"
              return model.name
            end
          end

          Rails.logger.debug "No model found for table: #{table_name}"
          # If no model found, return nil
          nil
        rescue StandardError => e
          # Log error but don't fail the whole process
          Rails.logger.debug "Error finding model class for table #{table_name}: #{e.message}"
          Rails.logger.debug e.backtrace.first(5).join("\n")
          nil
        end
      end
    end
  end
end
