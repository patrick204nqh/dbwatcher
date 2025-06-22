# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"
require "singleton"
require "logger"
require_relative "dbwatcher/version"
require_relative "dbwatcher/configuration"
require_relative "dbwatcher/logging"
require_relative "dbwatcher/tracker"
require_relative "dbwatcher/storage"
require_relative "dbwatcher/sql_logger"
require_relative "dbwatcher/model_extension"
require_relative "dbwatcher/middleware"
require_relative "dbwatcher/services/table_statistics_collector"
require_relative "dbwatcher/services/dashboard_data_aggregator"
require_relative "dbwatcher/services/query_filter_processor"
require_relative "dbwatcher/services/base_service"
require_relative "dbwatcher/services/diagram_data"
require_relative "dbwatcher/services/diagram_generator"
require_relative "dbwatcher/services/analyzers/base_analyzer"
require_relative "dbwatcher/services/analyzers/session_data_processor"
require_relative "dbwatcher/services/analyzers/table_summary_builder"
require_relative "dbwatcher/services/analyzers/schema_relationship_analyzer"
require_relative "dbwatcher/services/analyzers/model_association_analyzer"
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
