# frozen_string_literal: true

require "time"

module Dbwatcher
  module Storage
    module DataNormalizer
      # Normalize change data to use consistent symbol keys
      def normalize_change(change)
        return change unless change.is_a?(Hash)

        change.transform_keys(&:to_sym)
      end

      # Extract value by trying both string and symbol keys, returning symbol key value
      def extract_value(hash, key)
        return nil unless hash.is_a?(Hash)

        hash[key.to_sym] || hash[key.to_s]
      end

      # Normalize timestamp to consistent format
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
      def normalize_operation(operation)
        operation&.to_s&.upcase
      end

      # Normalize table name to string
      def normalize_table_name(table_name)
        table_name&.to_s
      end

      # Normalize record ID to string
      def normalize_record_id(record_id)
        record_id&.to_s
      end
    end
  end
end
