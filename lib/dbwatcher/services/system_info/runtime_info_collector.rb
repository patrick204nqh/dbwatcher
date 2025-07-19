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
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def collect_rails_config
          rails_config = {}

          return rails_config unless defined?(Rails)

          # Basic Rails configuration
          rails_config[:environment] = Rails.env
          rails_config[:version] = Rails.version
          rails_config[:root] = Rails.root.to_s

          # Rails application configuration
          if Rails.application
            app_config = Rails.application.config
            rails_config[:app_name] = Rails.application.class.name.split("::").first
            rails_config[:autoload_paths] =
              app_config.respond_to?(:autoload_paths) ? app_config.autoload_paths.size : nil
            rails_config[:eager_load_paths] =
              app_config.respond_to?(:eager_load_paths) ? app_config.eager_load_paths.size : nil
            rails_config[:eager_load] = app_config.respond_to?(:eager_load) ? app_config.eager_load : nil
            rails_config[:cache_classes] = app_config.respond_to?(:cache_classes) ? app_config.cache_classes : nil
            rails_config[:consider_all_requests_local] =
              app_config.respond_to?(:consider_all_requests_local) ? app_config.consider_all_requests_local : nil

            # Fix long line by breaking it up and removing redundant else
            perform_caching = if app_config.action_controller.respond_to?(:perform_caching)
                                app_config.action_controller.perform_caching
                              end
            rails_config[:action_controller] = { perform_caching: perform_caching }
          end

          rails_config
        rescue StandardError => e
          log_error "Failed to get Rails config: #{e.message}"
          {}
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        # Collect DBWatcher configuration
        #
        # @return [Hash] DBWatcher configuration
        # rubocop:disable Metrics/MethodLength
        def collect_dbwatcher_config
          config = Dbwatcher.configuration

          # Only include non-sensitive configuration options
          # Split long lines to avoid line length issues
          {
            system_info_refresh_interval:
              if config.respond_to?(:system_info_refresh_interval)
                config.system_info_refresh_interval
              else
                300
              end,
            collect_sensitive_env_vars:
              if config.respond_to?(:collect_sensitive_env_vars?)
                config.collect_sensitive_env_vars?
              else
                false
              end,
            system_info_include_performance_metrics:
              if config.respond_to?(:system_info_include_performance_metrics?)
                config.system_info_include_performance_metrics?
              else
                true
              end
          }
        rescue StandardError => e
          log_error "Failed to get DBWatcher config: #{e.message}"
          {}
        end
        # rubocop:enable Metrics/MethodLength

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
