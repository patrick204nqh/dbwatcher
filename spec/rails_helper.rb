# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("dummy/config/environment", __dir__)

require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "database_cleaner/active_record"

# Configure Capybara
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Chrome headless configuration
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Include Capybara DSL in all integration and feature tests
  config.include Capybara::DSL, type: :feature
  config.include Capybara::DSL, type: :system
  config.include Capybara::DSL, file_path: %r{spec/integration}

  # Database cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
