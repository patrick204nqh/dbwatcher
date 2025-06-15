# frozen_string_literal: true

require_relative "data_normalizer"

module Dbwatcher
  module Storage
    class TableAPI
      include DataNormalizer

      def initialize(storage)
        @storage = storage
        @filters = {}
      end

      def changes_for(table_name)
        @table_name = table_name
        self
      end

      def recent(days: 7)
        @filters[:recent_days] = days
        self
      end

      def by_operation(operation)
        @filters[:operation] = normalize_operation(operation)
        self
      end

      def all
        return [] unless @table_name

        changes = @storage.load_changes(@table_name)
        apply_filters(changes)
      end

      def most_active(limit: 10)
        # This would require aggregating across all tables
        # For now, return empty array - can be implemented later
        # TODO: Implement most active tables functionality with limit parameter
        _ = limit # Acknowledge the parameter for future use
        []
      end

      private

      def apply_filters(changes)
        result = changes

        if @filters[:recent_days]
          cutoff = Time.now - (@filters[:recent_days] * 24 * 60 * 60)
          result = result.select do |change|
            timestamp = normalize_timestamp(extract_value(change, "timestamp"))
            timestamp >= cutoff
          end
        end

        if @filters[:operation]
          result = result.select do |change|
            operation = normalize_operation(extract_value(change, "operation"))
            operation == @filters[:operation]
          end
        end

        result
      end
    end
  end
end
