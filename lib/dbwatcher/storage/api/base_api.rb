# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Api
      # Base class for all storage API classes
      #
      # This class provides common functionality and patterns for all
      # storage API implementations (SessionAPI, QueryAPI, TableAPI).
      # It establishes the foundation for the fluent interface pattern
      # and shared filtering capabilities.
      #
      # @abstract Subclass and implement specific API methods
      # @example
      #   class MyAPI < BaseAPI
      #     def my_filter(value)
      #       @filters[:my_key] = value
      #       self
      #     end
      #   end
      class BaseAPI
        include Storage::Concerns::DataNormalizer

        # Initialize the API with a storage backend
        #
        # @param storage [Object] storage backend instance
        def initialize(storage)
          @storage = storage
          @filters = {}
          @limit_value = nil
        end

        # Apply limit to results
        #
        # @param count [Integer] maximum number of results
        # @return [BaseAPI] self for method chaining
        def limit(count)
          @limit_value = count
          self
        end

        # Filter by conditions
        #
        # @param conditions [Hash] filtering conditions
        # @return [BaseAPI] self for method chaining
        def where(conditions)
          @filters.merge!(conditions)
          self
        end

        # Get all results after applying filters
        #
        # @return [Array] filtered results
        # @abstract Subclasses should implement this method
        def all
          raise NotImplementedError, "Subclasses must implement #all"
        end

        # Create a new record
        #
        # @param data [Hash] record data
        # @return [Hash] created record
        # @abstract Subclasses should implement this method if creation is supported
        def create(data)
          @storage.save(data)
        end

        protected

        attr_reader :storage, :filters, :limit_value

        # Apply common filters to a result set
        #
        # @param results [Array] raw results
        # @return [Array] filtered results
        def apply_common_filters(results)
          result = results

          # Apply limit if specified
          result = result.first(limit_value) if limit_value

          result
        end

        # Apply time-based filtering
        #
        # @param results [Array] results to filter
        # @param time_field [Symbol] field containing timestamp
        # @return [Array] filtered results
        def apply_time_filter(results, time_field)
          return results unless filters[:started_after]

          cutoff = filters[:started_after]
          results.select do |item|
            timestamp = item[time_field]
            next false unless timestamp

            begin
              Time.parse(timestamp.to_s) >= cutoff
            rescue ArgumentError
              false
            end
          end
        end

        # Apply pattern matching filter
        #
        # @param results [Array] results to filter
        # @param fields [Array<Symbol>] fields to search in
        # @param pattern [String] pattern to match
        # @return [Array] filtered results
        def apply_pattern_filter(results, fields, pattern)
          return results unless pattern

          results.select do |item|
            fields.any? do |field|
              value = item[field]
              value&.to_s&.include?(pattern)
            end
          end
        end

        # Safe value extraction with normalization
        #
        # @param item [Hash] item to extract from
        # @param key [Symbol] key to extract
        # @return [Object] extracted value
        def safe_extract(item, key)
          extract_value(item, key.to_s)
        end
      end
    end
  end
end
