# frozen_string_literal: true

module Dbwatcher
  module Storage
    class TableStorage < Base
      def initialize(session_storage)
        super()
        @session_storage = session_storage
      end

      def load_changes(table_name)
        changes = []

        @session_storage.all.each do |session_info|
          session_changes = collect_session_changes(session_info[:id], table_name)
          changes.concat(session_changes) if session_changes.any?
        end

        sort_by_timestamp(changes)
      end

      private

      def collect_session_changes(session_id, table_name)
        session = @session_storage.load(session_id)
        return [] unless session

        session.changes
               .select { |c| table_name_from_change(c) == table_name }
               .map { |change| enrich_with_session_data(change, session) }
      end

      def table_name_from_change(change)
        change["table_name"] || change[:table_name]
      end

      def enrich_with_session_data(change, session)
        stringified_change = change.is_a?(Hash) ? change.transform_keys(&:to_s) : change
        stringified_change.merge(
          "session_id" => session.id,
          "session_name" => session.name
        )
      end

      def sort_by_timestamp(changes)
        changes.sort_by { |c| c["timestamp"] || c[:timestamp] }.reverse
      end
    end
  end
end
