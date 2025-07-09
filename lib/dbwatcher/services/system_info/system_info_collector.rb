# frozen_string_literal: true

require_relative "machine_info_collector"
require_relative "database_info_collector"
require_relative "runtime_info_collector"
require_relative "../../logging"

module Dbwatcher
  module Services
    module SystemInfo
      # Main system information collector service
      #
      # Orchestrates the collection of system information from various sources
      # including machine, database, and runtime information.
      #
      # @example
      #   info = SystemInfo::SystemInfoCollector.call
      #   puts info[:machine][:hostname]
      #   puts info[:database][:adapter]
      #   puts info[:runtime][:ruby_version]
      class SystemInfoCollector
        include Dbwatcher::Logging

        # Class method to create instance and call
        #
        # @return [Hash] system information
        def self.call
          new.call
        end

        # Collect system information from all sources
        #
        # This method needs to be longer to properly handle all the collection
        # steps and error handling in a consistent way.
        #
        # @return [Hash] collected system information
        # rubocop:disable Metrics/MethodLength
        def call
          start_time = current_time
          log_info "#{self.class.name}: Starting system information collection"

          info = {
            machine: collect_machine_info,
            database: collect_database_info,
            runtime: collect_runtime_info,
            collected_at: current_time.iso8601,
            collection_duration: nil
          }

          info[:collection_duration] = (current_time - start_time).round(3)
          log_info "#{self.class.name}: Completed system information collection in #{info[:collection_duration]}s"

          info
        rescue StandardError => e
          log_error "System information collection failed: #{e.message}"
          {
            machine: {},
            database: {},
            runtime: {},
            collected_at: current_time.iso8601,
            collection_duration: nil,
            error: e.message
          }
        end
        # rubocop:enable Metrics/MethodLength

        private

        # Get current time, using Rails Time.current if available, otherwise Time.now
        #
        # @return [Time] current time
        def current_time
          defined?(Time.current) ? Time.current : Time.now
        end

        # Collect machine information safely
        #
        # @return [Hash] machine information or empty hash on error
        def collect_machine_info
          return {} unless Dbwatcher.configuration.collect_system_info

          MachineInfoCollector.call
        rescue StandardError => e
          log_error "Machine info collection failed: #{e.message}"
          { error: e.message }
        end

        # Collect database information safely
        #
        # @return [Hash] database information or empty hash on error
        def collect_database_info
          return {} unless Dbwatcher.configuration.collect_system_info

          DatabaseInfoCollector.call
        rescue StandardError => e
          log_error "Database info collection failed: #{e.message}"
          { error: e.message }
        end

        # Collect runtime information safely
        #
        # @return [Hash] runtime information or empty hash on error
        def collect_runtime_info
          return {} unless Dbwatcher.configuration.collect_system_info

          RuntimeInfoCollector.call
        rescue StandardError => e
          log_error "Runtime info collection failed: #{e.message}"
          { error: e.message }
        end
      end
    end
  end
end
