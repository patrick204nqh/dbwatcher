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
require_relative "dbwatcher/middleware"

# Tracking and SQL monitoring
require_relative "dbwatcher/tracker"
require_relative "dbwatcher/sql_logger"
require_relative "dbwatcher/model_extension"

# Base services
require_relative "dbwatcher/services/base_service"

# Core services
require_relative "dbwatcher/services/table_statistics_collector"
require_relative "dbwatcher/services/dashboard_data_aggregator"
require_relative "dbwatcher/services/query_filter_processor"

# System info services
require_relative "dbwatcher/services/system_info/machine_info_collector"
require_relative "dbwatcher/services/system_info/database_info_collector"
require_relative "dbwatcher/services/system_info/runtime_info_collector"
require_relative "dbwatcher/services/system_info/system_info_collector"

# General analyzers
require_relative "dbwatcher/services/analyzers/session_data_processor"
require_relative "dbwatcher/services/analyzers/table_summary_builder"

# Diagram data models
require_relative "dbwatcher/services/diagram_data/attribute"
require_relative "dbwatcher/services/diagram_data/entity"
require_relative "dbwatcher/services/diagram_data/relationship"
require_relative "dbwatcher/services/diagram_data/dataset"
require_relative "dbwatcher/services/diagram_data"

# Diagram analyzers
require_relative "dbwatcher/services/diagram_analyzers/base_analyzer"
require_relative "dbwatcher/services/diagram_analyzers/foreign_key_analyzer"
require_relative "dbwatcher/services/diagram_analyzers/inferred_relationship_analyzer"
require_relative "dbwatcher/services/diagram_analyzers/model_association_analyzer"

# Mermaid syntax builders
require_relative "dbwatcher/services/mermaid_syntax/base_builder"
require_relative "dbwatcher/services/mermaid_syntax/sanitizer"
require_relative "dbwatcher/services/mermaid_syntax/cardinality_mapper"
require_relative "dbwatcher/services/mermaid_syntax/erd_builder"
require_relative "dbwatcher/services/mermaid_syntax/class_diagram_builder"
require_relative "dbwatcher/services/mermaid_syntax/flowchart_builder"
require_relative "dbwatcher/services/mermaid_syntax_builder"

# Diagram strategies
require_relative "dbwatcher/services/diagram_strategies/base_diagram_strategy"
require_relative "dbwatcher/services/diagram_strategies/erd_diagram_strategy"
require_relative "dbwatcher/services/diagram_strategies/class_diagram_strategy"
require_relative "dbwatcher/services/diagram_strategies/flowchart_diagram_strategy"

# Diagram system
require_relative "dbwatcher/services/diagram_error_handler"
require_relative "dbwatcher/services/diagram_type_registry"
require_relative "dbwatcher/services/diagram_generator"
require_relative "dbwatcher/services/diagram_system"

# API services
require_relative "dbwatcher/services/api/base_api_service"
require_relative "dbwatcher/services/api/changes_data_service"
require_relative "dbwatcher/services/api/summary_data_service"
require_relative "dbwatcher/services/api/diagram_data_service"

# Rails engine
require_relative "dbwatcher/engine" if defined?(Rails)

# DBWatcher module
module Dbwatcher
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    # Get configuration
    #
    # @return [Configuration] configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure DBWatcher
    #
    # @yield [configuration] configuration
    # @return [Configuration] configuration
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
