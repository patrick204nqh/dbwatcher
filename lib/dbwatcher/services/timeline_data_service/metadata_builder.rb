# frozen_string_literal: true

module Dbwatcher
  module Services
    class TimelineDataService
      # Module for building timeline metadata
      module MetadataBuilder
        private

        # Build timeline metadata
        #
        # @return [Hash] timeline metadata
        def build_timeline_metadata
          return {} if @timeline_entries.empty?

          {
            total_operations: @timeline_entries.length,
            time_range: calculate_time_range,
            session_duration: calculate_session_duration,
            tables_affected: extract_affected_tables,
            operation_counts: count_operations_by_type,
            peak_activity_periods: find_peak_activity_periods
          }
        end

        # Calculate time range for the session
        #
        # @return [Hash] time range with start and end
        def calculate_time_range
          return {} if @timeline_entries.empty?

          start_time = Time.at(@timeline_entries.first[:raw_timestamp])
          end_time = Time.at(@timeline_entries.last[:raw_timestamp])

          {
            start: start_time.iso8601,
            end: end_time.iso8601
          }
        end

        # Calculate total session duration
        #
        # @return [String] formatted session duration
        def calculate_session_duration
          return "00:00" if @timeline_entries.length < 2

          duration = @timeline_entries.last[:raw_timestamp] - @timeline_entries.first[:raw_timestamp]
          format_duration(duration)
        end

        # Extract list of affected tables
        #
        # @return [Array<String>] unique table names
        def extract_affected_tables
          @timeline_entries.map { |entry| entry[:table_name] }.uniq.sort
        end

        # Count operations by type
        #
        # @return [Hash] operation counts
        def count_operations_by_type
          @timeline_entries.group_by { |entry| entry[:operation] }
                           .transform_values(&:count)
        end

        # Find peak activity periods
        #
        # @return [Array<Hash>] peak activity periods
        def find_peak_activity_periods
          return [] if @timeline_entries.length < 10

          # Group operations by 1-minute windows
          windows = @timeline_entries.group_by do |entry|
            timestamp = Time.at(entry[:raw_timestamp])
            Time.new(timestamp.year, timestamp.month, timestamp.day, timestamp.hour, timestamp.min, 0)
          end

          # Find windows with more than average activity
          average_ops = @timeline_entries.length / windows.length.to_f

          windows.select { |_, ops| ops.length > average_ops * 1.5 }
                 .map do |window_start, ops|
            {
              start: window_start.iso8601,
              end: (window_start + 1.minute).iso8601,
              operations_count: ops.length
            }
          end
        end
      end
    end
  end
end
