# frozen_string_literal: true

module Dbwatcher
  module Storage
    class NullSession
      def self.instance
        @instance ||= new
      end

      def id
        nil
      end

      def name
        "Unknown Session"
      end

      def changes
        []
      end

      def started_at
        nil
      end

      def ended_at
        nil
      end

      def present?
        false
      end

      def nil?
        true
      end
    end
  end
end
