# frozen_string_literal: true

module Dbwatcher
  # Logging module for DBWatcher components
  # Provides consistent logging interface across all services and components
  module Logging
    extend ActiveSupport::Concern if defined?(ActiveSupport)

    # Log an informational message with optional context
    # @param message [String] the log message
    # @param context [Hash] additional context data
    def log_info(message, context = {})
      log_with_level(:info, message, context)
    end

    # Log a debug message with optional context
    # Only logs if debug mode is enabled
    # @param message [String] the log message
    # @param context [Hash] additional context data
    def log_debug(message, context = {})
      return unless debug_enabled?

      log_with_level(:debug, message, context)
    end

    # Log a warning message with optional context
    # @param message [String] the log message
    # @param context [Hash] additional context data
    def log_warn(message, context = {})
      log_with_level(:warn, message, context)
    end

    # Log an error message with optional context
    # @param message [String] the log message
    # @param context [Hash] additional context data
    def log_error(message, context = {})
      log_with_level(:error, message, context)
    end

    # Check if debug logging is enabled
    # @return [Boolean] true if debug logging is enabled
    def debug_enabled?
      return Dbwatcher.configuration.debug_logging if defined?(Dbwatcher.configuration) &&
                                                      Dbwatcher.configuration.respond_to?(:debug_logging)
      return Rails.env.development? if defined?(Rails)

      false
    end

    private

    def log_with_level(level, message, context)
      logger = rails_logger || fallback_logger
      formatted_message = format_log_message(message, context)
      logger.public_send(level, formatted_message)
    end

    def format_log_message(message, context)
      base_message = "[DBWatcher:#{component_name}] #{message}"
      return base_message if context.empty?

      context_string = context.map { |k, v| "#{k}=#{v}" }.join(" ")
      "#{base_message} | #{context_string}"
    end

    def component_name
      if is_a?(Module) && !is_a?(Class)
        # For modules
        name.to_s.split("::").last
      elsif self.class.name
        # For classes
        self.class.name.split("::").last
      else
        # Fallback
        "Logger"
      end
    end

    def rails_logger
      return nil unless defined?(Rails)

      Rails.logger
    end

    def fallback_logger
      @fallback_logger ||= Logger.new($stdout).tap do |logger|
        logger.level = Logger::INFO
        logger.formatter = proc do |severity, datetime, _progname, msg|
          "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} [#{severity}] #{msg}\n"
        end
      end
    end
  end
end
