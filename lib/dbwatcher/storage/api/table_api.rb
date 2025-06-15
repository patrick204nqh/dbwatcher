# frozen_string_literal: true

require_relative "base_api"

module Dbwatcher
  module Storage
    module Api
      class TableAPI < BaseAPI
        # Filter changes for specific table
        #
        # @param table_name [String] table name
        # @return [TableAPI] self for method chaining
        def changes_for(table_name)
          @table_name = table_name
          self
        end

        # Filter to recent changes
        #
        # @param days [Integer] number of days back
        # @return [TableAPI] self for method chaining
        def recent(days: 7)
          filters[:recent_days] = days
          self
        end

        # Filter by operation type
        #
        # @param operation [String, Symbol] operation type
        # @return [TableAPI] self for method chaining
        def by_operation(operation)
          filters[:operation] = normalize_operation(operation)
          self
        end

        # Get all filtered changes
        #
        # @return [Array<Hash>] filtered changes
        def all
          return [] unless @table_name

          changes = storage.load_changes(@table_name)
          apply_filters(changes)
        end

        # Get most active tables
        #
        # @param limit [Integer] maximum number of tables
        # @return [Array<Hash>] most active tables
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

          # Apply recent filter using symbols only
          if filters[:recent_days]
            cutoff = Time.now - (filters[:recent_days] * 24 * 60 * 60)
            result = result.select do |change|
              timestamp = normalize_timestamp(safe_extract(change, :timestamp))
              timestamp >= cutoff
            end
          end

          # Apply operation filter using symbols only
          if filters[:operation]
            result = result.select do |change|
              operation = normalize_operation(safe_extract(change, :operation))
              operation == filters[:operation]
            end
          end

          # Apply common filters
          apply_common_filters(result)
        end
      end
    end
  end
end
