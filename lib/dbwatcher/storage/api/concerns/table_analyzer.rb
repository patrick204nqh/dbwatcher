# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Api
      module Concerns
        # Provides reusable table analysis functionality for API classes
        #
        # This concern extracts common table analysis logic used by API classes
        # to avoid duplication and provide consistent table analysis capabilities.
        #
        # @example
        #   class MyAPI < BaseAPI
        #     include Api::Concerns::TableAnalyzer
        #
        #     def analyze(session)
        #       build_tables_summary(session)
        #     end
        #   end
        module TableAnalyzer
          # Build tables summary from session changes
          #
          # @param session [Session] session to analyze
          # @return [Hash] tables summary hash
          def build_tables_summary(session)
            tables = {}
            process_session_changes(session, tables)
            tables
          end

          # Process all changes in a session
          #
          # @param session [Session] session with changes
          # @param tables [Hash] tables hash to populate
          # @return [void]
          def process_session_changes(session, tables)
            return unless session&.changes.respond_to?(:each)

            session.changes.each do |change|
              table_name = extract_table_name(change)
              next unless table_name

              initialize_table_data(tables, table_name)
              update_table_data(tables[table_name], change)
              update_sample_record(tables[table_name], change)
            end
          end

          # Extract table name from change data
          #
          # @param change [Hash] change data
          # @return [String, nil] table name or nil
          def extract_table_name(change)
            return nil unless change.is_a?(Hash)

            # Only use symbols since data is normalized
            change[:table_name]
          end

          # Initialize table data structure
          #
          # @param tables [Hash] tables hash
          # @param table_name [String] table name
          # @return [void]
          def initialize_table_data(tables, table_name)
            tables[table_name] ||= {
              name: table_name,
              operations: { "INSERT" => 0, "UPDATE" => 0, "DELETE" => 0 },
              changes: [],
              sample_record: nil,
              records: {},
              relationships: []
            }
          end

          # Update table data with change information
          #
          # @param table_data [Hash] table data hash
          # @param change [Hash] change data
          # @return [void]
          def update_table_data(table_data, change)
            # Count operations
            operation = extract_operation(change)
            table_data[:operations][operation] ||= 0
            table_data[:operations][operation] += 1

            # Add change to the list
            table_data[:changes] << change
          end

          # Update sample record to ensure all columns are captured with consistent ordering
          #
          # This method ensures that columns maintain a consistent order across all operations
          # by preserving the order established by the first record and appending new columns at the end.
          #
          # @param table_data [Hash] table data hash
          # @param change [Hash] change data
          # @return [void]
          def update_sample_record(table_data, change)
            snapshot = extract_record_snapshot(change)
            return unless snapshot.is_a?(Hash)

            if table_data[:sample_record].nil?
              # Initialize with first record's columns in their original order
              table_data[:sample_record] = snapshot.dup
            else
              # Maintain consistent column ordering by preserving existing order
              # and appending new columns at the end
              existing_keys = table_data[:sample_record].keys
              new_keys = snapshot.keys - existing_keys

              # Add new columns from the current snapshot
              new_keys.each do |key|
                table_data[:sample_record][key] = snapshot[key]
              end

              # Update existing columns with new values if they exist
              existing_keys.each do |key|
                if snapshot.key?(key)
                  table_data[:sample_record][key] = snapshot[key]
                end
              end
            end
          end

          # Update record history for analysis
          #
          # @param table_data [Hash] table data hash
          # @param change [Hash] change data
          # @return [void]
          def update_record_history(table_data, change)
            record_id = extract_record_id(change)
            return unless record_id

            table_data[:records][record_id] ||= []
            table_data[:records][record_id] << {
              operation: extract_operation(change),
              timestamp: extract_timestamp(change),
              changes: extract_field_changes(change)
            }
          end

          private

          # Extract operation from change data
          #
          # @param change [Hash] change data
          # @return [String] operation string
          def extract_operation(change)
            # Only use symbols since data is normalized
            operation = change[:operation] || "UNKNOWN"
            operation.to_s.upcase
          end

          # Extract record snapshot from change data
          #
          # @param change [Hash] change data
          # @return [Hash, nil] record snapshot or nil
          def extract_record_snapshot(change)
            # Only use symbols since data is normalized
            change[:record_snapshot]
          end

          # Extract record ID from change data
          #
          # @param change [Hash] change data
          # @return [String, nil] record ID or nil
          def extract_record_id(change)
            # Only use symbols since data is normalized
            id = change[:record_id]
            id&.to_s
          end

          # Extract timestamp from change data
          #
          # @param change [Hash] change data
          # @return [String, nil] timestamp string or nil
          def extract_timestamp(change)
            # Only use symbols since data is normalized
            change[:timestamp]
          end

          # Extract field changes from change data
          #
          # @param change [Hash] change data
          # @return [Hash] field changes hash
          def extract_field_changes(change)
            # Only use symbols since data is normalized
            change[:changes] || {}
          end
        end
      end
    end
  end
end
