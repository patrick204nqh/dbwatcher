# frozen_string_literal: true

module Dbwatcher
  class Storage
    class << self
      def save_session(session)
        return unless session&.id

        ensure_storage_directory

        # Save individual session file
        session_file = File.join(sessions_path, "#{session.id}.json")
        File.write(session_file, JSON.pretty_generate(session.to_h))

        # Update index
        update_index(session)

        # Clean old sessions if needed
        cleanup_old_sessions
      rescue => e
        warn "Failed to save session #{session&.id}: #{e.message}"
      end

      def load_session(id)
        return nil if id.nil? || id.empty?

        session_file = File.join(sessions_path, "#{id}.json")
        return nil unless File.exist?(session_file)

        data = JSON.parse(File.read(session_file), symbolize_names: true)
        Tracker::Session.new(data)
      rescue JSON::ParserError => e
        warn "Failed to parse session file #{id}: #{e.message}"
        nil
      rescue => e
        warn "Failed to load session #{id}: #{e.message}"
        nil
      end

      def all_sessions
        index_file = File.join(storage_path, "index.json")
        return [] unless File.exist?(index_file)

        JSON.parse(File.read(index_file), symbolize_names: true)
      rescue JSON::ParserError => e
        warn "Failed to parse sessions index: #{e.message}"
        []
      rescue => e
        warn "Failed to load sessions: #{e.message}"
        []
      end

      def reset!
        FileUtils.rm_rf(storage_path) if Dir.exist?(storage_path)
        ensure_storage_directory
      end

      private

      def storage_path
        Dbwatcher.configuration.storage_path
      end

      def sessions_path
        File.join(storage_path, "sessions")
      end

      def ensure_storage_directory
        FileUtils.mkdir_p(sessions_path)

        # Create index if it doesn't exist
        index_file = File.join(storage_path, "index.json")
        File.write(index_file, "[]") unless File.exist?(index_file)
      end

      def update_index(session)
        index_file = File.join(storage_path, "index.json")
        index = JSON.parse(File.read(index_file), symbolize_names: true)

        # Add new session summary to index
        index.unshift({
                        id: session.id,
                        name: session.name,
                        started_at: session.started_at,
                        ended_at: session.ended_at,
                        change_count: session.changes.count
                      })

        # Keep only max_sessions
        index = index.first(Dbwatcher.configuration.max_sessions)

        File.write(index_file, JSON.pretty_generate(index))
      rescue => e
        warn "Failed to update sessions index: #{e.message}"
      end

      def cleanup_old_sessions
        return unless Dbwatcher.configuration.auto_clean_after_days

        cutoff_date = Time.now - (Dbwatcher.configuration.auto_clean_after_days * 24 * 60 * 60)

        Dir.glob(File.join(sessions_path, "*.json")).each do |file|
          File.delete(file) if File.mtime(file) < cutoff_date
        end
      rescue => e
        warn "Failed to cleanup old sessions: #{e.message}"
      end
    end
  end
end
