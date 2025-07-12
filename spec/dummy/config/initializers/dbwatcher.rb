# frozen_string_literal: true

# Configure DBWatcher for development and testing
Rails.application.configure do
  # Add DBWatcher middleware to track HTTP requests
  config.middleware.use Dbwatcher::Middleware

  # Configure DBWatcher settings
  Dbwatcher.configure do |config|
    config.enabled = true
    config.auto_clean_after_days = 7
    config.max_sessions = 100

    # Enable debug logging in development environment
    config.debug_logging = true
  end
end
