# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../dummy/config/environment", __dir__)

require "capybara"
require "capybara/dsl"
require "selenium-webdriver"
require "database_cleaner/active_record"
require "rspec/expectations"
require "rspec/mocks"

# Include Capybara DSL methods in World
World(Capybara::DSL)
World(RSpec::Expectations)
World(RSpec::Mocks::ExampleMethods)

# Helper method for checking page success across different drivers
def expect_page_success
  expect(page).to have_css("body")
  # Only check status code for drivers that support it (rack_test)
  if page.driver.class.to_s.include?("RackTest")
    expect(page.status_code).to eq(200)
  end
end

# Configure RSpec mocks
Before do
  RSpec::Mocks.setup
end

After do
  RSpec::Mocks.verify
ensure
  RSpec::Mocks.teardown
end

# Configure database cleaner
DatabaseCleaner.strategy = :transaction

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
  RSpec::Mocks.verify
ensure
  RSpec::Mocks.teardown
end

# Configure Capybara
Capybara.configure do |config|
  config.app = Rails.application
  config.default_driver = :rack_test
  config.javascript_driver = :selenium_chrome_headless
  config.default_max_wait_time = 5
  config.server = :webrick # Use webrick for browser testing
end

# Set driver based on environment variable
if ENV["CAPYBARA_DRIVER"]
  Capybara.current_driver = ENV["CAPYBARA_DRIVER"].to_sym
  Capybara.javascript_driver = ENV["CAPYBARA_DRIVER"].to_sym
end

# Register browser drivers
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-web-security")
  options.add_argument("--allow-running-insecure-content")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--disable-web-security")
  options.add_argument("--allow-running-insecure-content")
  options.add_argument("--disable-features=VizDisplayCompositor")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :selenium_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--width=1400")
  options.add_argument("--height=1400")

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.register_driver :selenium_firefox_headless do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--headless")
  options.add_argument("--width=1400")
  options.add_argument("--height=1400")

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end
