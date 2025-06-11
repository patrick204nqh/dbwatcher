# frozen_string_literal: true

module Dbwatcher
  class Tracker
    class << self
      def track(name: nil, metadata: {})
        return yield unless Dbwatcher.configuration.enabled

        session = Session.new(
          id: SecureRandom.uuid,
          name: name || "Session #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}",
          metadata: metadata || {},
          started_at: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
          changes: []
        )

        Thread.current[:dbwatcher_session] = session

        begin
          result = yield
          session.ended_at = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
          Storage.save_session(session)
          result
        rescue => e
          session.ended_at = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
          Storage.save_session(session) rescue nil
          raise e
        ensure
          Thread.current[:dbwatcher_session] = nil
        end
      end

      def current_session
        Thread.current[:dbwatcher_session]
      end

      def record_change(change)
        session = current_session
        return unless session && change.is_a?(Hash)

        session.changes << change
      rescue => e
        warn "Failed to record change: #{e.message}"
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
          if respond_to?(setter_method)
            send(setter_method, value)
          end
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

        changes
          .select { |change| change.is_a?(Hash) && change[:table_name] && change[:operation] }
          .group_by { |change| "#{change[:table_name]},#{change[:operation]}" }
          .transform_values(&:count)
      rescue => e
        warn "Failed to calculate session summary: #{e.message}"
        {}
      end
    end
  end
end
