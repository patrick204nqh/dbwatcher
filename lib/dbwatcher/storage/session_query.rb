# frozen_string_literal: true

require "time"

module Dbwatcher
  module Storage
    class SessionQuery
      def initialize(storage)
        @storage = storage
        @conditions = {}
        @limit_value = nil
      end

      def find(id)
        @storage.load(id)
      end

      def all
        apply_filters(@storage.all)
      end

      def where(conditions)
        @conditions.merge!(conditions)
        self
      end

      def limit(count)
        @limit_value = count
        self
      end

      def recent(days: 7)
        cutoff = Time.now - (days * 24 * 60 * 60)
        where(started_after: cutoff)
      end

      def create(session)
        @storage.save(session)
      end

      def with_changes
        all.select { |s| @storage.load(s[:id])&.changes&.any? }
      end

      private

      def apply_filters(sessions)
        result = sessions
        result = result.select { |s| matches_conditions?(s) } if @conditions.any?
        result = result.first(@limit_value) if @limit_value
        result
      end

      def matches_conditions?(session)
        @conditions.all? do |key, value|
          case key
          when :started_after
            started_at = session[:started_at]
            started_at && Time.parse(started_at) >= value
          when :name
            session[:name]&.include?(value)
          else
            session[key] == value
          end
        end
      rescue ArgumentError, TypeError
        false
      end
    end
  end
end
