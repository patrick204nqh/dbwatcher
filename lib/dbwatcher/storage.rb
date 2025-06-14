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
      rescue StandardError => e
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
      rescue StandardError => e
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
      rescue StandardError => e
        warn "Failed to load sessions: #{e.message}"
        []
      end

      def reset!
        FileUtils.rm_rf(storage_path)
        ensure_storage_directory
      end

      # Query storage methods
      def save_query(query)
        return unless query

        ensure_storage_directory

        # Save to daily query log
        date = query[:timestamp].strftime("%Y-%m-%d")
        query_file = File.join(queries_path, "#{date}.json")

        queries = load_queries_for_date(date)
        queries << query

        # Limit queries per day
        max_queries = Dbwatcher.configuration.max_query_logs_per_day
        queries = queries.last(max_queries) if queries.count > max_queries

        File.write(query_file, JSON.pretty_generate(queries))
      rescue StandardError => e
        warn "Failed to save query: #{e.message}"
      end

      def load_queries_for_date(date)
        query_file = File.join(queries_path, "#{date}.json")
        return [] unless File.exist?(query_file)

        JSON.parse(File.read(query_file), symbolize_names: true)
      rescue JSON::ParserError => e
        warn "Failed to parse query file for #{date}: #{e.message}"
        []
      rescue StandardError => e
        warn "Failed to load queries for #{date}: #{e.message}"
        []
      end

      def load_table_changes(table_name)
        collect_changes_for_table(table_name)
      rescue StandardError => e
        warn "Failed to load table changes for #{table_name}: #{e.message}"
        []
      end

      def collect_changes_for_table(table_name)
        changes = []

        all_sessions.each do |session_info|
          session_changes = collect_changes_from_session(session_info[:id], table_name)
          changes.concat(session_changes) if session_changes.any?
        end

        sort_changes_by_timestamp(changes)
      end

      def collect_changes_from_session(session_id, table_name)
        session = load_session(session_id)
        return [] unless session

        filter_and_enrich_changes(session, table_name)
      end

      def filter_and_enrich_changes(session, table_name)
        session.changes
               .select { |c| (c["table_name"] || c[:table_name]) == table_name }
               .map { |change| enrich_change_with_session_data(change, session) }
      end

      def enrich_change_with_session_data(change, session)
        change.merge(
          "session_id" => session.id,
          "session_name" => session.name
        )
      end

      def sort_changes_by_timestamp(changes)
        changes.sort_by { |c| c["timestamp"] || c[:timestamp] }.reverse
      end

      private

      def storage_path
        path = Dbwatcher.configuration.storage_path
        Rails.logger.info "Storage.storage_path: Using storage path #{path}" if defined?(Rails)
        path
      end

      def sessions_path
        path = File.join(storage_path, "sessions")
        Rails.logger.info "Storage.sessions_path: Using path #{path}" if defined?(Rails)
        path
      end

      def queries_path
        File.join(storage_path, "queries")
      end

      def ensure_storage_directory
        FileUtils.mkdir_p(sessions_path)
        FileUtils.mkdir_p(queries_path) # Add queries directory

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
      rescue StandardError => e
        warn "Failed to update sessions index: #{e.message}"
      end

      def cleanup_old_sessions
        return unless Dbwatcher.configuration.auto_clean_after_days

        cutoff_date = Time.now - (Dbwatcher.configuration.auto_clean_after_days * 24 * 60 * 60)

        Dir.glob(File.join(sessions_path, "*.json")).each do |file|
          File.delete(file) if File.mtime(file) < cutoff_date
        end
      rescue StandardError => e
        warn "Failed to cleanup old sessions: #{e.message}"
      end
    end
  end
end
