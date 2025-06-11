# frozen_string_literal: true

module Dbwatcher
  module ModelExtension
    def self.included(base)
      extend ActiveSupport::Concern if defined?(ActiveSupport)

      base.class_eval do
        after_create :dbwatcher_track_create if respond_to?(:after_create)
        after_update :dbwatcher_track_update if respond_to?(:after_update)
        after_destroy :dbwatcher_track_destroy if respond_to?(:after_destroy)
      end
    end

    private

    def dbwatcher_track_create
      track_database_change(
        operation: "INSERT",
        changes: attributes.map { |column, value| build_change(column, nil, value) }
      )
    end

    def dbwatcher_track_update
      return unless saved_changes.any?

      track_database_change(
        operation: "UPDATE",
        changes: saved_changes.except("updated_at").map do |column, (old_val, new_val)|
          build_change(column, old_val, new_val)
        end
      )
    end

    def dbwatcher_track_destroy
      track_database_change(
        operation: "DELETE",
        changes: attributes.map { |column, value| build_change(column, value, nil) }
      )
    end

    def track_database_change(operation:, changes:)
      Dbwatcher::Tracker.record_change({
        table_name: self.class.table_name,
        record_id: id,
        operation: operation,
        timestamp: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
        changes: changes,
        record_snapshot: attributes
      })
    end

    def build_change(column, old_value, new_value)
      {
        column: column,
        old_value: old_value&.to_s,
        new_value: new_value&.to_s
      }
    end
  end
end
