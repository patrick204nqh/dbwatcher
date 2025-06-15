# frozen_string_literal: true

require_relative "session_operations"
require_relative "null_session"

module Dbwatcher
  module Storage
    class SessionStorage < Base
      def initialize
        super
        @sessions_path = File.join(storage_path, "sessions")
        @index_file = File.join(storage_path, "index.json")
        @operations = SessionOperations.new(@sessions_path, @index_file)

        setup_directories
      end

      def save(session)
        return false unless valid_session?(session)

        persist_session_file(session)
        update_session_index(session)
        trigger_cleanup

        true
      end

      def load(id)
        return NullSession.instance if invalid_id?(id)

        session_data = load_session_data(id)
        return NullSession.instance if session_data.empty?

        build_session_from_data(session_data)
      end

      def all
        safe_read_json(@index_file)
      end

      def reset!
        safe_operation("reset sessions") do
          FileUtils.rm_rf(@sessions_path)
          File.write(@index_file, "[]")
          setup_directories
        end
      end

      def cleanup_old_sessions
        return unless cleanup_enabled?

        cutoff_date = calculate_cleanup_cutoff
        remove_old_session_files(cutoff_date)
      end

      private

      def setup_directories
        file_manager.ensure_directory(@sessions_path)
        File.write(@index_file, "[]") unless File.exist?(@index_file)
      end

      def valid_session?(session)
        session.respond_to?(:id) && !session.id.nil?
      end

      def invalid_id?(id)
        id.nil? || id.to_s.strip.empty?
      end

      def persist_session_file(session)
        session_file = @operations.session_file_path(session.id)
        safe_write_json(session_file, session.to_h)
      end

      def update_session_index(session)
        index = safe_read_json(@index_file)
        session_summary = @operations.build_session_summary(session)

        updated_index = [session_summary] + index
        limited_index = @operations.apply_session_limits(updated_index)

        safe_write_json(@index_file, limited_index)
      end

      def trigger_cleanup
        cleanup_old_sessions
      end

      def load_session_data(id)
        session_file = @operations.session_file_path(id)
        safe_read_json(session_file, {})
      end

      def build_session_from_data(data)
        Storage::Session.new(data)
      rescue StandardError => e
        log_error("Failed to build session from data", e)
        NullSession.instance
      end

      def cleanup_enabled?
        Dbwatcher.configuration.auto_clean_after_days&.positive?
      end

      def calculate_cleanup_cutoff
        days = Dbwatcher.configuration.auto_clean_after_days
        Time.now - (days * 24 * 60 * 60)
      end

      def remove_old_session_files(cutoff_date)
        safe_operation("cleanup old sessions") do
          Dir.glob(File.join(@sessions_path, "*.json")).each do |file|
            File.delete(file) if File.mtime(file) < cutoff_date
          end
        end
      end
    end
  end
end
