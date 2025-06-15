# frozen_string_literal: true

require "time"
require_relative "base_api"
require_relative "concerns/table_analyzer"

module Dbwatcher
  module Storage
    module Api
      class SessionAPI < BaseAPI
        # Include table analysis capabilities for API layer
        include Api::Concerns::TableAnalyzer

        # Find a specific session by ID
        #
        # @param id [String] the session ID
        # @return [Session, nil] the session object or nil if not found
        def find(id)
          storage.load(id)
        end

        # Get all sessions
        #
        # @return [Array<Hash>] array of session data
        def all
          apply_filters(storage.all)
        end

        # Filter to recent sessions
        #
        # @param days [Integer] number of days back to include
        # @return [SessionAPI] self for method chaining
        def recent(days: 7)
          cutoff = Time.now - (days * 24 * 60 * 60)
          where(started_after: cutoff)
        end

        # Filter sessions that have changes
        #
        # @return [SessionAPI] self for method chaining
        def with_changes
          filters[:has_changes] = true
          self
        end

        # Filter sessions by status
        #
        # @param status [String, Symbol] session status (e.g., :active, :completed)
        # @return [SessionAPI] self for method chaining
        def by_status(status)
          filters[:status] = status.to_s
          self
        end

        # Filter sessions by name pattern
        #
        # @param pattern [String] name pattern to match
        # @return [SessionAPI] self for method chaining
        def by_name(pattern)
          filters[:name_pattern] = pattern
          self
        end

        # Get sessions with table analysis
        #
        # @return [Array<Hash>] sessions with analyzed table data
        def with_table_analysis
          all.map do |session_info|
            session = find(safe_extract(session_info, :id))
            next session_info unless session

            session_info.merge(
              tables_summary: build_tables_summary(session)
            )
          end.compact
        end

        # Get the most active sessions (by change count)
        #
        # @param limit [Integer] maximum number of sessions to return
        # @return [Array<Hash>] sessions ordered by activity
        def most_active(limit: 10)
          sessions_with_counts = all.map do |session_info|
            session = find(safe_extract(session_info, :id))
            change_count = session ? session.changes.length : 0
            session_info.merge(change_count: change_count)
          end

          sessions_with_counts
            .sort_by { |s| -s[:change_count] }
            .first(limit)
        end

        private

        def apply_filters(sessions)
          result = sessions

          # Apply time-based filters using symbols only
          result = apply_time_filter(result, :started_at) if filters[:started_after]

          # Apply status filter using symbols only
          result = result.select { |s| safe_extract(s, :status) == filters[:status] } if filters[:status]

          # Apply name pattern filter using symbols only
          result = apply_pattern_filter(result, %i[name id], filters[:name_pattern]) if filters[:name_pattern]

          # Apply has_changes filter
          if filters[:has_changes]
            result = result.select do |s|
              session = find(safe_extract(s, :id))
              session&.changes&.any?
            end
          end

          # Apply common filters (limit, etc.)
          apply_common_filters(result)
        end
      end
    end
  end
end
