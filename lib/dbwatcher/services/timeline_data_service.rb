# frozen_string_literal: true

require "digest"

module Dbwatcher
  module Services
    # Timeline Data Service for processing session data into chronological timeline format
    #
    # This service transforms session changes into a chronologically ordered timeline
    # with enhanced metadata for visualization and filtering. It includes caching
    # for performance optimization and supports large sessions efficiently.
    #
    # @example
    #   service = TimelineDataService.new(session)
    #   result = service.call
    #   timeline = result[:timeline]
    #   metadata = result[:metadata]
    class TimelineDataService
      # Initialize the timeline data service
      #
      # @param session [Session] session object containing changes data
      def initialize(session)
        @session = session
        @timeline_entries = []
        @start_time = Time.current
      end

      # Process session data into timeline format
      #
      # @return [Hash] processed timeline data with metadata
      def call
        Rails.logger.info("Processing timeline data for session #{@session.id}")

        validate_session_data
        build_timeline_entries
        sort_chronologically
        enhance_with_metadata
        result = build_result

        Rails.logger.info(
          "Timeline processing completed for session #{@session.id} (#{@timeline_entries.length} entries)"
        )

        result
      rescue StandardError => e
        Rails.logger.error("Timeline processing failed for session #{@session.id}: #{e.message}")
        build_error_result(e)
      end

      private

      # Validate session data before processing
      #
      # @raise [ArgumentError] if session data is invalid
      def validate_session_data
        raise ArgumentError, "Session is required" unless @session
        raise ArgumentError, "Session ID is required" unless @session.id
        raise ArgumentError, "Session changes are required" unless @session.changes
      end

      # Build timeline entries from session changes
      #
      # @return [void]
      def build_timeline_entries
        @session.changes.each_with_index do |change, index|
          next unless valid_change?(change)

          @timeline_entries << create_timeline_entry(change, index)
        end
      end

      # Check if a change is valid for timeline processing
      #
      # @param change [Hash] change data
      # @return [Boolean] true if change is valid
      def valid_change?(change)
        change.is_a?(Hash) &&
          change[:table_name] &&
          change[:operation] &&
          change[:timestamp]
      end

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
        "#{@session.id}_entry_#{sequence}_#{Digest::SHA1.hexdigest("#{change[:table_name]}_#{change[:operation]}_#{sequence}")[0..7]}"
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

      # Sort timeline entries chronologically
      #
      # @return [void]
      def sort_chronologically
        @timeline_entries.sort_by! { |entry| entry[:raw_timestamp] }
      end

      # Enhance timeline entries with additional metadata
      #
      # @return [void]
      def enhance_with_metadata
        return if @timeline_entries.empty?

        session_start_time = @timeline_entries.first[:raw_timestamp]

        @timeline_entries.each_with_index do |entry, index|
          entry[:relative_time] = calculate_relative_time(entry[:raw_timestamp], session_start_time)
          entry[:duration_from_previous] = calculate_duration_from_previous(entry, index)
          entry[:operation_group] = determine_operation_group(entry, index)
        end
      end

      # Calculate relative time from session start
      #
      # @param timestamp [Float] entry timestamp
      # @param session_start [Float] session start timestamp
      # @return [String] formatted relative time
      def calculate_relative_time(timestamp, session_start)
        seconds = timestamp - session_start
        format_duration(seconds)
      end

      # Calculate duration from previous operation
      #
      # @param entry [Hash] current entry
      # @param index [Integer] entry index
      # @return [Integer] duration in milliseconds
      def calculate_duration_from_previous(entry, index)
        return 0 if index.zero?

        previous_entry = @timeline_entries[index - 1]
        ((entry[:raw_timestamp] - previous_entry[:raw_timestamp]) * 1000).round
      end

      # Determine operation group for related operations
      #
      # @param entry [Hash] current entry
      # @param index [Integer] entry index
      # @return [String] operation group identifier
      def determine_operation_group(entry, index)
        # Group operations on same table within 1 second
        return "single_op" if index.zero?

        previous_entry = @timeline_entries[index - 1]
        time_diff = entry[:raw_timestamp] - previous_entry[:raw_timestamp]

        if time_diff <= 1.0 && entry[:table_name] == previous_entry[:table_name]
          "#{entry[:table_name]}_batch_#{index / 10}" # Group every 10 operations
        else
          "single_op"
        end
      end

      # Format duration in human-readable format
      #
      # @param seconds [Float] duration in seconds
      # @return [String] formatted duration
      def format_duration(seconds)
        if seconds < 60
          format("%<minutes>02d:%<seconds>02d", minutes: 0, seconds: seconds.to_i)
        elsif seconds < 3600
          minutes = seconds / 60
          format("%<minutes>02d:%<seconds>02d", minutes: minutes.to_i, seconds: (seconds % 60).to_i)
        else
          hours = seconds / 3600
          minutes = (seconds % 3600) / 60
          format("%<hours>02d:%<minutes>02d:%<seconds>02d",
                 hours: hours.to_i, minutes: minutes.to_i, seconds: (seconds % 60).to_i)
        end
      end

      # Build final result hash
      #
      # @return [Hash] complete timeline result
      def build_result
        {
          timeline: @timeline_entries,
          metadata: build_timeline_metadata,
          summary: build_timeline_summary,
          errors: []
        }
      end

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

      # Build timeline summary
      #
      # @return [Hash] timeline summary
      def build_timeline_summary
        {
          total_entries: @timeline_entries.length,
          processing_time: (Time.current - @start_time).round(3)
        }
      end

      # Build error result
      #
      # @param error [StandardError] error that occurred
      # @return [Hash] error result
      def build_error_result(error)
        {
          timeline: [],
          metadata: {},
          summary: { error: error.message },
          errors: [{ type: "processing_error", message: error.message }]
        }
      end

      # Get model class for a table using the TableSummaryBuilder service
      #
      # @param table_name [String] database table name
      # @return [String, nil] model class name or nil if not found
      def get_model_class_for_table(table_name)
        # Use cache to avoid repeated lookups
        @model_class_cache ||= {}
        return @model_class_cache[table_name] if @model_class_cache.key?(table_name)

        # Delegate to TableSummaryBuilder for model class lookup
        builder = Dbwatcher::Services::Analyzers::TableSummaryBuilder.new(@session)
        @model_class_cache[table_name] = builder.send(:find_model_class, table_name)
      end
    end
  end
end
