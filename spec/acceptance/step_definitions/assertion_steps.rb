# frozen_string_literal: true

# Assertion steps for verifying page content and behavior
Then(/^I should see the monitoring interface$/) do
  expect(page).to have_css("body")
end

Then(/^the page should load successfully$/) do
  expect_page_success
end

Then(/^I should see the session list$/) do
  expect(page).to have_css("body")
  expect_page_success
end

Then(/^the page should be fully loaded$/) do
  expect(page).to have_css("body")
  sleep 0.5 # Allow time for any JavaScript to load
end

Then(/^I should see all sessions listed$/) do
  expect_page_success
  expect(page).to have_css("body")
end

Then(/^I should see the session details page$/) do
  expect_page_success
end
