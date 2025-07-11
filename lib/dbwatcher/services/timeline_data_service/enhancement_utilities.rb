# frozen_string_literal: true

module Dbwatcher
  module Services
    class TimelineDataService
      # Module for enhancing timeline entries and utility methods
      module EnhancementUtilities
        private

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
end
