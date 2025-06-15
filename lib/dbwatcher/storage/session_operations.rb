# frozen_string_literal: true

module Dbwatcher
  module Storage
    class SessionOperations
      def initialize(sessions_path, index_file)
        @sessions_path = sessions_path
        @index_file = index_file
      end

      def session_file_path(session_id)
        File.join(@sessions_path, "#{session_id}.json")
      end

      def build_session_summary(session)
        {
          id: session.id,
          name: session.name,
          started_at: session.started_at,
          ended_at: session.ended_at,
          change_count: session.changes.count
        }
      end

      def apply_session_limits(sessions)
        max_sessions = Dbwatcher.configuration.max_sessions
        return sessions unless max_sessions&.positive?

        sessions.first(max_sessions)
      end
    end
  end
end
