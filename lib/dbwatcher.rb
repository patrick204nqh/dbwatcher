# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"
require "singleton"
require "logger"

# Core components
require_relative "dbwatcher/version"
require_relative "dbwatcher/configuration"
require_relative "dbwatcher/logging"

# Storage layer
require_relative "dbwatcher/storage"

# Tracking and SQL monitoring
require_relative "dbwatcher/tracker"
require_relative "dbwatcher/sql_logger"
require_relative "dbwatcher/model_extension"
require_relative "dbwatcher/middleware"

# Base services
require_relative "dbwatcher/services/base_service"

# Core services
require_relative "dbwatcher/services/table_statistics_collector"
require_relative "dbwatcher/services/dashboard_data_aggregator"
require_relative "dbwatcher/services/query_filter_processor"

# General analyzers
require_relative "dbwatcher/services/analyzers/session_data_processor"
require_relative "dbwatcher/services/analyzers/table_summary_builder"

# Diagram system
require_relative "dbwatcher/services/diagram_system"

# API services
require_relative "dbwatcher/services/api/base_api_service"
require_relative "dbwatcher/services/api/changes_data_service"
require_relative "dbwatcher/services/api/summary_data_service"
require_relative "dbwatcher/services/api/diagram_data_service"

# Rails engine
require_relative "dbwatcher/engine" if defined?(Rails)

module Dbwatcher
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def track(name: nil, metadata: {}, &block)
      Tracker.track(name: name, metadata: metadata, &block)
    end

    def current_session
      Tracker.current_session
    end

    # Clears all stored data (sessions and queries)
    #
    # @return [Integer] total number of files removed
    def clear_all
      Storage.clear_all
    end
  end
end
