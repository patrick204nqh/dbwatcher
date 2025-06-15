# frozen_string_literal: true

module Dbwatcher
  module Storage
    class ChangeProcessor
      include Concerns::DataNormalizer

      def initialize(session_storage)
        @session_storage = session_storage
        @session_cache = {}
      end

      def process_table_changes(table_name)
        all_changes = collect_all_changes(table_name)
        sort_changes_by_timestamp(all_changes)
      end

      private

      def collect_all_changes(table_name)
        changes = []

        @session_storage.all.each do |session_info|
          session_changes = extract_table_changes_from_session(session_info[:id], table_name)
          changes.concat(session_changes)
        end

        changes
      end

      def extract_table_changes_from_session(session_id, table_name)
        session = load_session_with_cache(session_id)
        return [] unless session.respond_to?(:changes) && session.changes

        session.changes
               .select { |change| matches_table?(change, table_name) }
               .map { |change| enrich_change(change, session) }
      end

      def load_session_with_cache(session_id)
        @session_cache[session_id] ||= @session_storage.load(session_id)
      end

      def matches_table?(change, table_name)
        extract_value(change, :table_name) == table_name
      end

      def enrich_change(change, session)
        normalized_change = normalize_change(change)
        add_session_context(normalized_change, session)
      end

      def add_session_context(change, session)
        change.merge(
          session_id: session.id,
          session_name: session.name
        )
      end

      def sort_changes_by_timestamp(changes)
        changes.sort_by { |change| normalize_timestamp(extract_value(change, "timestamp")) }.reverse
      end
    end
  end
end
