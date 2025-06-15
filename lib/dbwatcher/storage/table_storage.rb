# frozen_string_literal: true

require_relative "change_processor"

module Dbwatcher
  module Storage
    class TableStorage < Base
      def initialize(session_storage)
        super()
        @change_processor = ChangeProcessor.new(session_storage)
      end

      def load_changes(table_name)
        return [] if invalid_table_name?(table_name)

        @change_processor.process_table_changes(table_name)
      rescue StandardError => e
        log_error("Failed to load changes for table #{table_name}", e)
        []
      end

      private

      def invalid_table_name?(table_name)
        table_name.nil? || table_name.to_s.strip.empty?
      end
    end
  end
end
