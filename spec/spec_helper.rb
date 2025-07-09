# frozen_string_literal: true

# Configure SimpleCov for test coverage
if ENV["COVERAGE"] || ENV["CI"]
  require "simplecov"
  require "simplecov_json_formatter"

  SimpleCov.start "rails" do
    add_filter "/spec/"
    add_filter "/features/"
    add_group "Tracker", "lib/dbwatcher/tracker"
    add_group "Storage", "lib/dbwatcher/storage"
    add_group "Services", "lib/dbwatcher/services"
    add_group "Controllers", "app/controllers"

    # Use JSON formatter for CI
    if ENV["CI"]
      SimpleCov.coverage_dir "coverage"
      SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
    end
  end
end

# Load the entire dbwatcher library
require "dbwatcher"

# Load Rails environment for Rails-dependent tests
if File.exist?(File.expand_path("dummy/config/environment", __dir__))
  ENV["RAILS_ENV"] ||= "test"
  require File.expand_path("dummy/config/environment", __dir__)
  require "rspec/rails"
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Shared configuration for all tests
  config.order = :random

  # Color output
  config.color = true

  # Rails-specific configuration
  if defined?(Rails)
    config.infer_spec_type_from_file_location!
    config.filter_rails_from_backtrace!

    # Database cleaner configuration if ActiveRecord is available
    if defined?(ActiveRecord)
      require "database_cleaner/active_record"

      config.use_transactional_fixtures = false

      config.before(:suite) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
      end

      config.before(:each) do
        DatabaseCleaner.start
      end

      config.after(:each) do
        DatabaseCleaner.clean
      end
    end

    # Capybara configuration if available
    if defined?(Capybara)
      require "capybara/rails"
      require "capybara/rspec"

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

      # Include Capybara DSL in all integration and feature tests
      config.include Capybara::DSL, type: :feature
      config.include Capybara::DSL, type: :system
      config.include Capybara::DSL, file_path: %r{spec/integration}

      config.after(:each) do
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end
    end
  end
end
