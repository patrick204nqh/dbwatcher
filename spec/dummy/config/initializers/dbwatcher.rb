# frozen_string_literal: true

# Configure DBWatcher for development and testing
Rails.application.configure do
  # Add DBWatcher middleware to track HTTP requests
  config.middleware.use Dbwatcher::Middleware

  # Simple configuration using new cleaner option names
  Dbwatcher.configure do |config|
    config.enabled = true
    config.max_sessions = 100
    config.auto_clean_days = 7
    config.debug_mode = true
  end
end
