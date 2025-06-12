# frozen_string_literal: true

# Navigation steps for visiting different pages
When(/^I visit the DBWatcher dashboard$/) do
  visit "/dbwatcher"
end

When(/^I visit the DBWatcher interface in a browser$/) do
  visit "/dbwatcher"
end

When(/^I visit the sessions index page$/) do
  visit "/dbwatcher/sessions"
end

When(/^I click on a session$/) do
  visit "/dbwatcher/sessions/detailed-session"
end
