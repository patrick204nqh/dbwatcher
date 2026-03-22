# frozen_string_literal: true

require_relative "../../logging"

module Dbwatcher
  module Services
    module SystemInfo
      # Runtime information collector service
      #
      # Collects runtime-specific information including Ruby version, Rails version,
      # loaded gems, environment variables, and application configuration.
      #
      # @example
      #   info = SystemInfo::RuntimeInfoCollector.call
      #   puts info[:ruby_version]
      #   puts info[:rails_version]
      #   puts info[:gem_count]
      #
      # This class is necessarily complex due to the comprehensive runtime information
      # it needs to collect across different Ruby and Rails environments.
      # rubocop:disable Metrics/ClassLength
      class RuntimeInfoCollector
        include Dbwatcher::Logging

        # Class method to create instance and call
        #
        # @return [Hash] runtime information
        def self.call
          new.call
        end

        # Collect runtime information
        #
        # @return [Hash] collected runtime information
        # rubocop:disable Metrics/MethodLength
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
        # rubocop:enable Metrics/MethodLength

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
          return {} unless Dbwatcher.configuration.system_info_include_performance_metrics?

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
            paths: Dbwatcher.configuration.system_info_include_performance_metrics? ? $LOAD_PATH.first(10) : []
          }
        rescue StandardError => e
          log_error "Failed to get load path info: #{e.message}"
          { size: 0, paths: [] }
        end

        # Collect environment variables (filtered for security)
        #
        # @return [Hash] filtered environment variables
        # rubocop:disable Metrics/MethodLength
        def collect_environment_variables
          return {} unless Dbwatcher.configuration.collect_sensitive_env_vars?

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
        # rubocop:enable Metrics/MethodLength

        # Collect application configuration
        #
        # @return [Hash] application configuration
        def collect_application_config
          config = {}

          # Collect Rails configuration if available
          config[:rails] = collect_rails_config if defined?(Rails)

          # Collect DBWatcher configuration
          config[:dbwatcher] = collect_dbwatcher_config if defined?(Dbwatcher)

          config
        rescue StandardError => e
          log_error "Failed to get application config: #{e.message}"
          {}
        end

        # Collect Rails configuration if available
        #
        # @return [Hash] Rails configuration
        def collect_rails_config
          return {} unless defined?(Rails)

          rails_config = basic_rails_config
          rails_config.merge!(rails_app_config) if Rails.application
          rails_config
        rescue StandardError => e
          log_error "Failed to get Rails config: #{e.message}"
          {}
        end

        # Basic Rails environment/version info
        #
        # @return [Hash]
        def basic_rails_config
          {
            environment: Rails.env,
            version: Rails.version,
            root: Rails.root.to_s
          }
        end

        # Rails application-level config settings
        #
        # @return [Hash]
        def rails_app_config
          app_config = Rails.application.config
          {
            app_name: Rails.application.class.name.split("::").first,
            autoload_paths: safe_config_value(app_config, :autoload_paths, &:size),
            eager_load_paths: safe_config_value(app_config, :eager_load_paths, &:size),
            eager_load: safe_config_value(app_config, :eager_load),
            cache_classes: safe_config_value(app_config, :cache_classes),
            consider_all_requests_local: safe_config_value(app_config, :consider_all_requests_local),
            action_controller: { perform_caching: rails_perform_caching(app_config) }
          }
        end

        # Safely read a config attribute, returning nil if not supported
        #
        # @param config [Object] config object
        # @param attr [Symbol] attribute name
        # @yield [value] optional transform block
        # @return [Object, nil]
        def safe_config_value(config, attr)
          return nil unless config.respond_to?(attr)

          value = config.public_send(attr)
          block_given? ? yield(value) : value
        end

        # Read perform_caching from action_controller config
        #
        # @param app_config [Object]
        # @return [Boolean, nil]
        def rails_perform_caching(app_config)
          return nil unless app_config.action_controller.respond_to?(:perform_caching)

          app_config.action_controller.perform_caching
        end

        # Collect DBWatcher configuration
        #
        # @return [Hash] DBWatcher configuration
        def collect_dbwatcher_config
          config = Dbwatcher.configuration
          {
            system_info_refresh_interval: dbwatcher_config_value(config, :system_info_refresh_interval, 300),
            collect_sensitive_env_vars: dbwatcher_config_value(config, :collect_sensitive_env_vars?, false),
            system_info_include_performance_metrics:
              dbwatcher_config_value(config, :system_info_include_performance_metrics?, true)
          }
        rescue StandardError => e
          log_error "Failed to get DBWatcher config: #{e.message}"
          {}
        end

        # Safely read a Dbwatcher configuration value with a fallback default
        #
        # @param config [Object] configuration object
        # @param method_name [Symbol] method to call
        # @param default [Object] fallback if not supported
        # @return [Object]
        def dbwatcher_config_value(config, method_name, default)
          config.respond_to?(method_name) ? config.public_send(method_name) : default
        end

        # Sanitize database configuration to remove sensitive information
        #
        # @param db_config [Hash] database configuration
        # @return [Hash] sanitized database configuration
        def sanitize_database_config(db_config)
          return {} unless db_config.is_a?(Hash)

          # Create a copy to avoid modifying the original
          sanitized = db_config.dup

          # Remove sensitive information
          %w[password username user].each do |key|
            sanitized.delete(key)
            sanitized.delete(key.to_sym)
          end

          # Keep only basic connection info
          safe_keys = %w[adapter host port database pool timeout]
          sanitized.select { |k, _| safe_keys.include?(k.to_s) }
        rescue StandardError => e
          log_error "Failed to sanitize database config: #{e.message}"
          {}
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
