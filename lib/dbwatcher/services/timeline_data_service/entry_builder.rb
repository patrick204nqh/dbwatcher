# frozen_string_literal: true

require "digest"

module Dbwatcher
  module Services
    class TimelineDataService
      # Module for building timeline entries
      module EntryBuilder
        private

        # Create a timeline entry from change data
        #
        # @param change [Hash] change data
        # @param sequence [Integer] sequence number
        # @return [Hash] timeline entry
        def create_timeline_entry(change, sequence)
          timestamp = parse_timestamp(change[:timestamp])

          {
            id: generate_entry_id(change, sequence),
            timestamp: timestamp,
            sequence: sequence,
            table_name: change[:table_name],
            operation: change[:operation],
            record_id: extract_record_id(change),
            changes: format_changes(change),
            metadata: extract_metadata(change),
            model_class: get_model_class_for_table(change[:table_name]),
            raw_timestamp: timestamp.to_f
          }
        end

        # Generate unique ID for timeline entry
        #
        # @param change [Hash] change data
        # @param sequence [Integer] sequence number
        # @return [String] unique entry ID
        def generate_entry_id(change, sequence)
          data = "#{change[:table_name]}_#{change[:operation]}_#{sequence}"
          hash = Digest::SHA1.hexdigest(data)[0..7]
          "#{@session.id}_entry_#{sequence}_#{hash}"
        end

        # Parse timestamp from various formats
        #
        # @param timestamp [String, Time, Integer] timestamp value
        # @return [Time] parsed timestamp
        def parse_timestamp(timestamp)
          case timestamp
          when Time
            timestamp
          when String
            Time.parse(timestamp)
          when Integer, Float
            Time.at(timestamp)
          else
            Time.current
          end
        rescue ArgumentError
          Time.current
        end

        # Extract record ID from change data
        #
        # @param change [Hash] change data
        # @return [String, nil] record ID if available
        def extract_record_id(change)
          change[:record_id] || change[:id] || change.dig(:changes, :id)
        end

        # Format changes for timeline display
        #
        # @param change [Hash] change data
        # @return [Hash] formatted changes
        def format_changes(change)
          raw_changes = change[:changes] || change[:data] || {}
          return {} unless raw_changes.is_a?(Hash)

          raw_changes.transform_values do |value|
            case value
            when Hash
              value # Already formatted as { from: x, to: y }
            else
              { to: value } # Simple value change
            end
          end
        end

        # Extract metadata from change data
        #
        # @param change [Hash] change data
        # @return [Hash] metadata hash
        def extract_metadata(change)
          {
            duration_ms: change[:duration_ms] || change[:duration],
            affected_rows: change[:affected_rows] || change[:rows_affected] || 1,
            query_fingerprint: change[:query_fingerprint] || change[:sql_fingerprint],
            connection_id: change[:connection_id] || change[:connection],
            query_type: determine_query_type(change[:operation])
          }.compact
        end

        # Determine query type from operation
        #
        # @param operation [String] database operation
        # @return [String] query type
        def determine_query_type(operation)
          case operation&.upcase
          when "INSERT", "CREATE"
            "write"
          when "UPDATE", "MODIFY"
            "update"
          when "DELETE", "DROP"
            "delete"
          when "SELECT", "SHOW"
            "read"
          else
            "unknown"
          end
        end
      end
    end
  end
end
