# frozen_string_literal: true

module Dbwatcher
  class Tracker
    class << self
      def track(name: nil, metadata: {}, &block)
        return yield unless Dbwatcher.configuration.enabled

        session = create_session(name, metadata)
        Thread.current[:dbwatcher_session] = session

        execute_with_session(session, &block)
      ensure
        Thread.current[:dbwatcher_session] = nil
      end

      def current_session
        Thread.current[:dbwatcher_session]
      end

      def record_change(change)
        session = current_session
        return unless session && change.is_a?(Hash)

        session.changes << change
      rescue StandardError => e
        warn "Failed to record change: #{e.message}"
      end

      private

      def create_session(name, metadata)
        Session.new(
          id: SecureRandom.uuid,
          name: name || "Session #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}",
          metadata: metadata || {},
          started_at: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
          changes: []
        )
      end

      def execute_with_session(session, &block)
        result = block.call
        finalize_session(session)
        result
      rescue StandardError => e
        finalize_session(session)
        raise e
      end

      def finalize_session(session)
        session.ended_at = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
        Storage.save_session(session)
      rescue StandardError
        nil
      end
    end

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
