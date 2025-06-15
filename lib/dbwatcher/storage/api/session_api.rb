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
          sessions
            .then { |s| filter_by_start_time(s) }
            .then { |s| filter_by_status(s) }
            .then { |s| filter_by_name_pattern(s) }
            .then { |s| filter_by_changes(s) }
            .then { |s| apply_common_filters(s) }
        end

        def filter_by_start_time(sessions)
          return sessions unless filters[:started_after]

          apply_time_filter(sessions, :started_at)
        end

        def filter_by_status(sessions)
          return sessions unless filters[:status]

          sessions.select { |s| safe_extract(s, :status) == filters[:status] }
        end

        def filter_by_name_pattern(sessions)
          return sessions unless filters[:name_pattern]

          apply_pattern_filter(sessions, %i[name id], filters[:name_pattern])
        end

        def filter_by_changes(sessions)
          return sessions unless filters[:has_changes]

          sessions.select do |s|
            session = find(safe_extract(s, :id))
            session&.changes&.any?
          end
        end
      end
    end
  end
end
