# frozen_string_literal: true

module Dbwatcher
  # Configuration class for DBWatcher
  #
  # Simplified configuration with logical groupings and sensible defaults
  class Configuration
    # Core settings - what users need most
    attr_accessor :enabled, :storage_path

    # Session management - how data is stored and cleaned
    attr_accessor :max_sessions, :auto_clean_days

    # Query tracking - performance monitoring
    attr_accessor :track_queries

    # System info - debugging and monitoring
    attr_accessor :system_info, :debug_mode

    # Advanced diagram options - available but not commonly needed
    attr_accessor :diagram_show_methods, :diagram_max_attributes,
                  :diagram_attribute_types, :diagram_relationship_labels,
                  :diagram_show_attributes, :diagram_show_cardinality

    # Initialize with default values
    def initialize
      # Core settings
      @enabled = true
      @storage_path = default_storage_path

      # Session management
      @max_sessions = 50
      @auto_clean_days = 7

      # Query tracking
      @track_queries = false

      # System info
      @system_info = true
      @debug_mode = false

      # Advanced diagram options - sensible defaults
      @diagram_show_methods = false
      @diagram_max_attributes = 10
      @diagram_attribute_types = true
      @diagram_relationship_labels = true
      @diagram_show_attributes = true
      @diagram_show_cardinality = true
    end

    # Fixed defaults for options that are still used in codebase but not configurable
    def slow_query_threshold
      200 # Fixed default value
    end

    def diagram_direction
      "LR" # Fixed default value
    end

    # Fixed defaults for complex options that are still used in codebase but not configurable
    def max_query_logs_per_day = 1000
    def system_info_refresh_interval = 5 * 60
    def system_info_cache_duration = 60 * 60

    def collect_sensitive_env_vars?
      false
    end

    def system_info_include_performance_metrics?
      true
    end

    # Validate configuration
    def valid?
      validate_storage_path
      validate_max_sessions
      validate_auto_clean_days
      true
    end

    private

    # Default storage path based on Rails or current directory
    def default_storage_path
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        Rails.root.join("tmp", "dbwatcher").to_s
      else
        File.join(Dir.pwd, "tmp", "dbwatcher")
      end
    end

    # Validate storage path
    def validate_storage_path
      return if storage_path.nil? || Dir.exist?(storage_path)

      begin
        FileUtils.mkdir_p(storage_path)
      rescue StandardError => e
        raise ConfigurationError, "Failed to create storage path: #{e.message}"
      end
    end

    # Validate max sessions
    def validate_max_sessions
      return if max_sessions.is_a?(Integer) && max_sessions.positive?

      raise ConfigurationError, "max_sessions must be a positive integer"
    end

    # Validate auto clean days
    def validate_auto_clean_days
      return if auto_clean_days.is_a?(Integer) && auto_clean_days.positive?

      raise ConfigurationError, "auto_clean_days must be a positive integer"
    end
  end

  # Configuration error class
  class ConfigurationError < StandardError; end
end
