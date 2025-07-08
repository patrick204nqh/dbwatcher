# frozen_string_literal: true

require_relative "../logging"

module Dbwatcher
  module Services
    # Runtime information collector service
    #
    # Collects runtime-specific information including Ruby version, Rails version,
    # loaded gems, environment variables, and application configuration.
    #
    # @example
    #   info = RuntimeInfoCollector.call
    #   puts info[:ruby_version]
    #   puts info[:rails_version]
    #   puts info[:gem_count]
    class RuntimeInfoCollector
      include Dbwatcher::Logging

      # Class method to create instance and call
      #
      # @return [Hash] runtime information
      def self.call
        new.call
      end

      def call
        log_info "#{self.class.name}: Collecting runtime information"

        {
          ruby_version: collect_ruby_version,
          ruby_engine: collect_ruby_engine,
          ruby_patchlevel: collect_ruby_patchlevel,
          rails_version: collect_rails_version,
          rails_env: collect_rails_env,
          environment: collect_environment,
          pid: Process.pid,
          gem_count: collect_gem_count,
          loaded_gems: collect_loaded_gems,
          load_path: collect_load_path_info,
          environment_variables: collect_environment_variables,
          application_config: collect_application_config
        }
      rescue StandardError => e
        log_error "Runtime info collection failed: #{e.message}"
        { error: e.message }
      end

      private

      # Collect Ruby version information
      #
      # @return [String] Ruby version
      def collect_ruby_version
        RUBY_VERSION
      rescue StandardError => e
        log_error "Failed to get Ruby version: #{e.message}"
        "unknown"
      end

      # Collect Ruby engine information
      #
      # @return [String] Ruby engine (e.g., ruby, jruby, rbx)
      def collect_ruby_engine
        defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
      rescue StandardError => e
        log_error "Failed to get Ruby engine: #{e.message}"
        "unknown"
      end

      # Collect Ruby patchlevel
      #
      # @return [String] Ruby patchlevel
      def collect_ruby_patchlevel
        RUBY_PATCHLEVEL.to_s
      rescue StandardError => e
        log_error "Failed to get Ruby patchlevel: #{e.message}"
        "unknown"
      end

      # Collect Rails version if available
      #
      # @return [String] Rails version or nil
      def collect_rails_version
        return nil unless defined?(Rails)

        Rails.version
      rescue StandardError => e
        log_error "Failed to get Rails version: #{e.message}"
        nil
      end

      # Collect Rails environment if available
      #
      # @return [String] Rails environment or nil
      def collect_rails_env
        return nil unless defined?(Rails)

        Rails.env
      rescue StandardError => e
        log_error "Failed to get Rails environment: #{e.message}"
        nil
      end

      # Collect current environment
      #
      # @return [String] current environment
      def collect_environment
        ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
      rescue StandardError => e
        log_error "Failed to get environment: #{e.message}"
        "unknown"
      end

      # Collect loaded gems count
      #
      # @return [Integer] number of loaded gems
      def collect_gem_count
        Gem.loaded_specs.size
      rescue StandardError => e
        log_error "Failed to get gem count: #{e.message}"
        0
      end

      # Collect loaded gems information
      #
      # @return [Hash] loaded gems with versions
      def collect_loaded_gems
        return {} unless Dbwatcher.configuration.system_info_include_performance_metrics

        gems = {}
        Gem.loaded_specs.each do |name, spec|
          gems[name] = spec.version.to_s
        end
        gems
      rescue StandardError => e
        log_error "Failed to get loaded gems: #{e.message}"
        {}
      end

      # Collect load path information
      #
      # @return [Hash] load path statistics
      def collect_load_path_info
        {
          size: $LOAD_PATH.size,
          paths: Dbwatcher.configuration.system_info_include_performance_metrics ? $LOAD_PATH.first(10) : []
        }
      rescue StandardError => e
        log_error "Failed to get load path info: #{e.message}"
        { size: 0, paths: [] }
      end

      # Collect environment variables (filtered for security)
      #
      # @return [Hash] filtered environment variables
      def collect_environment_variables
        return {} unless Dbwatcher.configuration.collect_sensitive_env_vars

        env_vars = {}

        # Safe environment variables to include
        safe_vars = %w[
          RAILS_ENV
          RACK_ENV
          RUBY_VERSION
          PATH
          HOME
          USER
          SHELL
          TERM
          LANG
          LC_ALL
          TZ
          RAILS_LOG_LEVEL
          RAILS_SERVE_STATIC_FILES
          RAILS_CACHE_ID
          RAILS_RELATIVE_URL_ROOT
          BUNDLE_GEMFILE
          BUNDLE_PATH
          GEM_HOME
          GEM_PATH
        ]

        safe_vars.each do |var|
          env_vars[var] = ENV[var] if ENV[var]
        end

        env_vars
      rescue StandardError => e
        log_error "Failed to get environment variables: #{e.message}"
        {}
      end

      # Collect application configuration
      #
      # @return [Hash] application configuration
      def collect_application_config
        config = {}

        # Rails application config if available
        config[:rails] = collect_rails_config if defined?(Rails) && Rails.respond_to?(:application) && Rails.application

        # DBWatcher configuration
        config[:dbwatcher] = collect_dbwatcher_config

        config
      rescue StandardError => e
        log_error "Failed to get application config: #{e.message}"
        {}
      end

      # Collect Rails configuration
      #
      # @return [Hash] Rails configuration
      def collect_rails_config
        rails_config = {}

        app = Rails.application
        config = app.config

        # Basic Rails settings
        rails_config[:application_name] = app.class.name.split("::").first if app.class.name
        rails_config[:eager_load] = config.eager_load if config.respond_to?(:eager_load)
        rails_config[:cache_classes] = config.cache_classes if config.respond_to?(:cache_classes)
        if config.respond_to?(:consider_all_requests_local)
          rails_config[:consider_all_requests_local] =
            config.consider_all_requests_local
        end
        rails_config[:time_zone] = config.time_zone if config.respond_to?(:time_zone)
        rails_config[:encoding] = config.encoding if config.respond_to?(:encoding)

        # Database config
        if config.respond_to?(:database_configuration)
          rails_config[:database_config] = sanitize_database_config(config.database_configuration)
        end

        rails_config
      rescue StandardError => e
        log_error "Failed to get Rails config: #{e.message}"
        {}
      end

      # Collect DBWatcher configuration
      #
      # @return [Hash] DBWatcher configuration
      def collect_dbwatcher_config
        config = Dbwatcher.configuration

        {
          storage_path: config.storage_path,
          enabled: config.enabled,
          max_sessions: config.max_sessions,
          auto_clean_after_days: config.auto_clean_after_days,
          track_queries: config.track_queries,
          slow_query_threshold: config.slow_query_threshold,
          mount_path: config.mount_path,
          collect_system_info: config.collect_system_info,
          system_info_refresh_interval: config.system_info_refresh_interval,
          collect_sensitive_env_vars: config.collect_sensitive_env_vars,
          system_info_include_performance_metrics: config.system_info_include_performance_metrics
        }
      rescue StandardError => e
        log_error "Failed to get DBWatcher config: #{e.message}"
        {}
      end

      # Sanitize database configuration (remove sensitive information)
      #
      # @param db_config [Hash] database configuration
      # @return [Hash] sanitized database configuration
      def sanitize_database_config(db_config)
        return {} unless db_config.is_a?(Hash)

        sanitized = {}
        db_config.each do |env, config|
          next unless config.is_a?(Hash)

          sanitized[env] = config.dup
          sanitized[env].delete("password")
          sanitized[env].delete(:password)
          sanitized[env].delete("username") unless Dbwatcher.configuration.collect_sensitive_env_vars
          sanitized[env].delete(:username) unless Dbwatcher.configuration.collect_sensitive_env_vars
        end
        sanitized
      rescue StandardError => e
        log_error "Failed to sanitize database config: #{e.message}"
        {}
      end
    end
  end
end
