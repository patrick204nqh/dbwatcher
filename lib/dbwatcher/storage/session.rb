# frozen_string_literal: true

module Dbwatcher
  module Storage
    class Session
      attr_accessor :id, :name, :metadata, :started_at, :ended_at, :changes

      def initialize(attrs = {})
        # Set default values
        @changes = []
        @metadata = {}

        # Set provided attributes
        attrs.each do |key, value|
          setter_method = "#{key}="
          send(setter_method, value) if respond_to?(setter_method)
        end
      end

      def to_h
        {
          id: id,
          name: name,
          metadata: metadata,
          started_at: started_at,
          ended_at: ended_at,
          changes: changes
        }
      end

      def summary
        return {} unless changes.is_a?(Array)

        valid_changes = filter_valid_changes
        group_changes_by_operation(valid_changes)
      rescue StandardError => e
        warn "Failed to calculate session summary: #{e.message}"
        {}
      end

      private

      def filter_valid_changes
        changes.select { |change| valid_change?(change) }
      end

      def valid_change?(change)
        change.is_a?(Hash) && change[:table_name] && change[:operation]
      end

      def group_changes_by_operation(valid_changes)
        valid_changes
          .group_by { |change| "#{change[:table_name]},#{change[:operation]}" }
          .transform_values(&:count)
      end
    end
  end
end
