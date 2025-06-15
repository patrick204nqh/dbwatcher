# frozen_string_literal: true

module Dbwatcher
  module Storage
    class SessionOperations
      # Include data normalization capabilities
      include Concerns::DataNormalizer
      def initialize(sessions_path, index_file)
        @sessions_path = sessions_path
        @index_file = index_file
      end

      def session_file_path(session_id)
        File.join(@sessions_path, "#{session_id}.json")
      end

      def build_session_summary(session)
        session_data = normalize_session_data(session)

        {
          id: session_data[:id],
          name: session_data[:name],
          started_at: session_data[:started_at],
          ended_at: session_data[:ended_at],
          change_count: (session_data[:changes] || []).count
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
