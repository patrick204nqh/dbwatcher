# frozen_string_literal: true

module Dbwatcher
  # Configuration class for DBWatcher
  #
  # This class manages all configuration options for DBWatcher, including
  # storage, tracking, and diagram visualization settings.
  class Configuration
    # Storage configuration
    attr_accessor :storage_path, :enabled, :max_sessions, :auto_clean_after_days

    # Query tracking configuration
    attr_accessor :track_queries, :slow_query_threshold, :max_query_logs_per_day

    # Routing configuration
    attr_accessor :mount_path

    # Diagram configuration
    attr_accessor :diagram_show_attributes, :diagram_show_methods, :diagram_show_cardinality,
                  :diagram_max_attributes, :diagram_attribute_types, :diagram_relationship_labels,
                  :diagram_preserve_table_case, :diagram_direction, :diagram_cardinality_format,
                  :diagram_show_attribute_count, :diagram_show_method_count

    # Initialize with default values
    def initialize
      # Storage configuration defaults
      @storage_path = default_storage_path
      @enabled = true
      @max_sessions = 50
      @auto_clean_after_days = 7

      # Query tracking configuration defaults
      @track_queries = true
      @slow_query_threshold = 200 # milliseconds
      @max_query_logs_per_day = 1000

      # Routing configuration defaults
      @mount_path = "/dbwatcher"

      # Diagram configuration defaults
      @diagram_show_attributes = true
      @diagram_show_methods = false # Hide methods by default
      @diagram_show_cardinality = true
      @diagram_max_attributes = 10
      @diagram_attribute_types = true # Changed from array to boolean
      @diagram_relationship_labels = true # Changed from symbol to boolean
      @diagram_preserve_table_case = false # Changed from true to false
      @diagram_direction = "LR" # Left to right by default
      @diagram_cardinality_format = :simple # Use simpler 1:N format
      @diagram_show_attribute_count = true
      @diagram_show_method_count = true
    end

    # Validate configuration
    #
    # @return [Boolean] true if configuration is valid
    def validate!
      validate_storage_path
      validate_max_sessions
      validate_auto_clean_after_days
      validate_slow_query_threshold
      validate_max_query_logs_per_day
      true
    end

    private

    # Default storage path based on Rails or current directory
    #
    # @return [String] default storage path
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

    # Validate auto clean after days
    def validate_auto_clean_after_days
      return if auto_clean_after_days.is_a?(Integer) && auto_clean_after_days.positive?

      raise ConfigurationError, "auto_clean_after_days must be a positive integer"
    end

    # Validate slow query threshold
    def validate_slow_query_threshold
      return if slow_query_threshold.is_a?(Integer) && slow_query_threshold.positive?

      raise ConfigurationError, "slow_query_threshold must be a positive integer"
    end

    # Validate max query logs per day
    def validate_max_query_logs_per_day
      return if max_query_logs_per_day.is_a?(Integer) && max_query_logs_per_day.positive?

      raise ConfigurationError, "max_query_logs_per_day must be a positive integer"
    end
  end

  # Configuration error class
  class ConfigurationError < StandardError; end
end
