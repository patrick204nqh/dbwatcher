# frozen_string_literal: true

module Dbwatcher
  module Storage
    class QueryValidator
      REQUIRED_FIELDS = [:timestamp].freeze

      def self.valid?(query)
        return false unless query.is_a?(Hash)

        REQUIRED_FIELDS.all? { |field| query.key?(field) && !query[field].nil? }
      end

      def self.validate!(query)
        raise ArgumentError, "Query must be a Hash" unless query.is_a?(Hash)

        missing_fields = REQUIRED_FIELDS.reject { |field| query.key?(field) }
        return true if missing_fields.empty?

        raise ArgumentError, "Missing required fields: #{missing_fields.join(", ")}"
      end
    end
  end
end
