#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for the Dbwatcher gem

require "bundler/setup"
require_relative "lib/dbwatcher"

puts "🔍 Dbwatcher Demo"
puts "=" * 50

# Configure Dbwatcher
Dbwatcher.configure do |config|
  config.enabled = true
  config.storage_path = File.join(__dir__, "tmp", "dbwatcher_demo")
end

puts "✅ Configured Dbwatcher"
puts "   Storage path: #{Dbwatcher.configuration.storage_path}"
puts "   Enabled: #{Dbwatcher.configuration.enabled}"
puts

# Clean previous demo data
Dbwatcher.reset!
puts "🧹 Cleaned previous demo data"
puts

# Demo tracking
puts "📝 Demo tracking session..."
result = Dbwatcher.track(name: "Demo Session", metadata: { demo: true }) do
  puts "   Inside tracked block - this would track DB changes in a Rails app"

  # Simulate some database changes by directly calling the tracker
  tracker = Dbwatcher::Tracker.current_session
  if tracker
    # Simulate creating a user
    Dbwatcher::Tracker.record_change({
                                       table_name: "users",
                                       record_id: 123,
                                       operation: "INSERT",
                                       timestamp: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
                                       changes: [
                                         { column: "name", old_value: nil, new_value: "John Doe" },
                                         { column: "email", old_value: nil, new_value: "john@example.com" }
                                       ],
                                       record_snapshot: { id: 123, name: "John Doe", email: "john@example.com" }
                                     })

    # Simulate updating the user
    Dbwatcher::Tracker.record_change({
                                       table_name: "users",
                                       record_id: 123,
                                       operation: "UPDATE",
                                       timestamp: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
                                       changes: [
                                         { column: "name", old_value: "John Doe", new_value: "John Smith" }
                                       ],
                                       record_snapshot: { id: 123, name: "John Smith", email: "john@example.com" }
                                     })
  end

  "Demo completed successfully!"
end

puts "✅ #{result}"
puts

# Show the tracked data
puts "📊 Checking stored sessions..."
sessions = Dbwatcher::Storage.all_sessions
if sessions.any?
  session = sessions.first
  puts "   Found session: #{session[:name]}"
  puts "   Changes: #{session[:change_count]}"

  # Load full session details
  full_session = Dbwatcher::Storage.load_session(session[:id])
  puts "   Summary: #{full_session.summary}" if full_session
else
  puts "   No sessions found"
end

puts
puts "🎉 Demo completed! In a Rails app, visit /dbwatcher to see the UI."
