# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Concerns
      # Provides consistent data normalization capabilities across storage classes
      #
      # This concern standardizes how different data types are normalized to ensure
      # consistent symbol-key usage and proper data formatting throughout the storage layer.
      #
      # @example
      #   class MyStorage < BaseStorage
      #     include Concerns::DataNormalizer
      #
      #     def save(data)
      #       normalized_data = normalize_session_data(data)
      #       # ... save logic
      #     end
      #   end
      module DataNormalizer
        # Normalizes session input to hash with consistent symbol keys
        #
        # @param session [Hash, Object] session data to normalize
        # @return [Hash] normalized session hash with symbol keys
        def normalize_session_data(session)
          case session
          when Hash
            normalize_hash_keys(session)
          when ->(s) { s.respond_to?(:to_h) }
            normalize_hash_keys(session.to_h)
          else
            extract_object_attributes(session)
          end
        end

        # Normalizes hash keys to symbols (Rails-compatible)
        #
        # @param hash [Hash] hash to normalize
        # @return [Hash] hash with symbolized keys
        def normalize_hash_keys(hash)
          return hash unless hash.is_a?(Hash)

          if hash.respond_to?(:with_indifferent_access)
            hash.with_indifferent_access.symbolize_keys
          else
            hash.transform_keys { |key| key.to_s.to_sym }
          end
        end

        # Normalize change data to use consistent symbol keys
        #
        # @param change [Hash] change data to normalize
        # @return [Hash] normalized change hash with symbol keys
        def normalize_change(change)
          return change unless change.is_a?(Hash)

          normalize_hash_keys(change)
        end

        # Extract value by trying both string and symbol keys
        #
        # @param hash [Hash] hash to extract from
        # @param key [String, Symbol] key to extract
        # @return [Object] extracted value or nil
        def extract_value(hash, key)
          return nil unless hash.is_a?(Hash)

          hash[key.to_sym] || hash[key.to_s]
        end

        # Normalize timestamp to consistent format
        #
        # @param timestamp [String, Time, Numeric] timestamp to normalize
        # @return [Time] normalized timestamp
        def normalize_timestamp(timestamp)
          return Time.at(0) unless timestamp

          case timestamp
          when String
            Time.parse(timestamp)
          when Time
            timestamp
          when Numeric
            Time.at(timestamp)
          else
            Time.at(0)
          end
        rescue ArgumentError, TypeError
          Time.at(0)
        end

        # Normalize operation to uppercase string
        #
        # @param operation [String, Symbol] operation to normalize
        # @return [String] uppercase operation string
        def normalize_operation(operation)
          operation&.to_s&.upcase
        end

        # Normalize table name to string
        #
        # @param table_name [String, Symbol] table name to normalize
        # @return [String] normalized table name
        def normalize_table_name(table_name)
          table_name&.to_s
        end

        # Normalize record ID to string
        #
        # @param record_id [String, Integer] record ID to normalize
        # @return [String] normalized record ID
        def normalize_record_id(record_id)
          record_id&.to_s
        end

        private

        # Extracts attributes from objects that don't respond to to_h
        #
        # @param object [Object] object to extract attributes from
        # @return [Hash] extracted attributes hash
        def extract_object_attributes(object)
          {
            id: object.respond_to?(:id) ? object.id : nil,
            name: object.respond_to?(:name) ? object.name : nil,
            started_at: object.respond_to?(:started_at) ? object.started_at : nil,
            ended_at: object.respond_to?(:ended_at) ? object.ended_at : nil,
            changes: object.respond_to?(:changes) ? object.changes : []
          }
        end
      end
    end
  end
end
