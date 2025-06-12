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
  @session_with_queries = {
    id: "detailed-session",
    name: "Detailed Session",
    started_at: Time.now.iso8601
  }
  allow(Dbwatcher::Storage).to receive(:load_session)
    .with("detailed-session")
    .and_return(@session_with_queries)
end
