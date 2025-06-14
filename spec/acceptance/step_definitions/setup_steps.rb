# frozen_string_literal: true

# Application setup and configuration steps
Given(/^I have a Rails application with DBWatcher mounted$/) do
  expect(Rails.application).to be_present
end

# Data setup steps
Given(/^there are multiple database sessions$/) do
  @sessions = [
    { id: "session-1", name: "Session 1", started_at: Time.now.iso8601 },
    { id: "session-2", name: "Session 2", started_at: Time.now.iso8601 },
    { id: "session-3", name: "Session 3", started_at: Time.now.iso8601 }
  ]
  allow(Dbwatcher::Storage).to receive(:all_sessions).and_return(@sessions)
end

Given(/^there is a database session with queries$/) do
  # Create a real session with real data
  session_id = SecureRandom.uuid
  @session_with_queries = Dbwatcher::Tracker::Session.new({
                                                            id: session_id,
                                                            name: "Detailed Session",
                                                            started_at: Time.now.iso8601,
                                                            ended_at: Time.now.iso8601,
                                                            changes: []
                                                          })

  # Initialize @sessions if it doesn't exist
  @sessions ||= []

  # Add the session to the sessions list so it can be found
  sessions_with_detailed = @sessions + [{
    id: session_id,
    name: "Detailed Session",
    started_at: Time.now.iso8601
  }]
  allow(Dbwatcher::Storage).to receive(:all_sessions).and_return(sessions_with_detailed)

  # Mock load_session to return our session for any ID that matches the pattern
  allow(Dbwatcher::Storage).to receive(:load_session) do |id|
    @session_with_queries if id == session_id
  end
end
