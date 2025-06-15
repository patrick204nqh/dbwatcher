# frozen_string_literal: true

require_relative "storage/session"

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
        Storage::Session.new(
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
        Storage.sessions.create(session)
      rescue StandardError
        nil
      end
    end
  end
end
