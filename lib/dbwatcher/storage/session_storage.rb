# frozen_string_literal: true

module Dbwatcher
  module Storage
    class SessionStorage < Base
      def initialize
        super
        @sessions_path = File.join(storage_path, "sessions")
        @index_file = File.join(storage_path, "index.json")
        ensure_session_directories
      end

      def save(session)
        return unless session&.id

        save_session_file(session)
        update_index(session)
        cleanup_old_sessions
      end

      def load(id)
        return nil if id.nil? || id.empty?

        session_file = File.join(@sessions_path, "#{id}.json")
        data = safe_read_json(session_file)
        return nil if data.empty?

        Tracker::Session.new(data)
      end

      def all
        safe_read_json(@index_file)
      end

      def reset!
        FileUtils.rm_rf(@sessions_path)
        File.write(@index_file, "[]")
        ensure_session_directories
      end

      def cleanup_old_sessions
        return unless Dbwatcher.configuration.auto_clean_after_days

        cutoff_date = Time.now - (Dbwatcher.configuration.auto_clean_after_days * 24 * 60 * 60)

        Dir.glob(File.join(@sessions_path, "*.json")).each do |file|
          File.delete(file) if File.mtime(file) < cutoff_date
        end
      rescue StandardError => e
        warn "Failed to cleanup old sessions: #{e.message}"
      end

      private

      def ensure_session_directories
        FileUtils.mkdir_p(@sessions_path)
        File.write(@index_file, "[]") unless File.exist?(@index_file)
      end

      def save_session_file(session)
        session_file = File.join(@sessions_path, "#{session.id}.json")
        safe_write_json(session_file, session.to_h)
      end

      def update_index(session)
        index = safe_read_json(@index_file)

        index.unshift({
                        id: session.id,
                        name: session.name,
                        started_at: session.started_at,
                        ended_at: session.ended_at,
                        change_count: session.changes.count
                      })

        # Keep only max_sessions
        index = index.first(Dbwatcher.configuration.max_sessions)
        safe_write_json(@index_file, index)
      end
    end
  end
end
