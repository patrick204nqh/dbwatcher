# frozen_string_literal: true

require_relative "timeline_data_service/metadata_builder"
require_relative "timeline_data_service/entry_builder"
require_relative "timeline_data_service/enhancement_utilities"

module Dbwatcher
  module Services
    # Timeline Data Service for processing session data into chronological timeline format
    #
    # This service transforms session changes into a chronologically ordered timeline
    # with enhanced metadata for visualization and filtering.
    #
    # @example
    #   service = TimelineDataService.new(session)
    #   result = service.call
    #   timeline = result[:timeline]
    #   metadata = result[:metadata]
    class TimelineDataService
      include MetadataBuilder
      include EntryBuilder
      include EnhancementUtilities

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

      # Sort timeline entries chronologically
      #
      # @return [void]
      def sort_chronologically
        @timeline_entries.sort_by! { |entry| entry[:raw_timestamp] }
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
    end
  end
end
