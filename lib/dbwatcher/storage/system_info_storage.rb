# frozen_string_literal: true

require_relative "../services/system_info/system_info_collector"
require_relative "../logging"

module Dbwatcher
  module Storage
    # System information storage class
    #
    # Handles storage, caching, and retrieval of system information data.
    # Provides intelligent caching with configurable TTL and refresh capabilities.
    #
    # @example
    #   storage = SystemInfoStorage.new
    #   info = storage.cached_info
    #   storage.refresh_info
    #
    # This class is necessarily complex due to the comprehensive system information
    # storage and retrieval functionality it provides.
    # rubocop:disable Metrics/ClassLength
    class SystemInfoStorage < BaseStorage
      include Dbwatcher::Logging
      # Initialize system info storage
      def initialize
        super
        @info_file = File.join(storage_path, "system_info.json")
      end

      # Save system information to storage
      #
      # @param info [Hash] system information data
      # @return [Boolean] true if successful
      def save_info(info)
        # Convert all keys to strings before saving to ensure consistent format
        info_with_string_keys = convert_keys_to_strings(info)
        safe_write_json(@info_file, info_with_string_keys)
      end

      # Load system information from storage
      #
      # @return [Hash] system information data or empty hash
      def load_info
        # Override the base class default to return {} instead of []
        safe_operation("read JSON from #{@info_file}", {}) do
          result = file_manager.read_json(@info_file)
          result = {} if result.is_a?(Array) && result.empty?
          # Convert string keys back to symbols for consistent access in the app
          convert_keys_to_symbols(result)
        end
      end

      # Refresh system information by collecting new data
      #
      # @return [Hash] refreshed system information
      def refresh_info
        log_info "Refreshing system information"

        info = Services::SystemInfo::SystemInfoCollector.call
        save_info(info)

        log_info "System information refreshed successfully"
        # Return the info with symbol keys for consistent access
        convert_keys_to_symbols(info)
      rescue StandardError => e
        log_error "Failed to refresh system information: #{e.message}"

        # Return cached info if available, otherwise empty hash with error
        cached_info = load_info
        cached_info.empty? ? { error: e.message } : cached_info
      end

      # Get cached system information with TTL support
      #
      # @param max_age [Integer] maximum age in seconds (default: from config)
      # @return [Hash] cached or refreshed system information
      def cached_info(max_age: nil)
        max_age ||= Dbwatcher.configuration.system_info_cache_duration

        info = load_info

        # If no cached info exists, collect new data
        return refresh_info if info.empty?

        # Check if cached info is expired
        if info_expired?(info, max_age)
          log_info "System information cache expired, refreshing"
          return refresh_info
        end

        log_info "Using cached system information"
        info
      rescue StandardError => e
        log_error "Failed to get cached system information: #{e.message}"
        { error: e.message }
      end

      # Check if system information is available
      #
      # @return [Boolean] true if system information exists
      def info_available?
        !load_info.empty?
      rescue StandardError => e
        log_error "Failed to check info availability: #{e.message}"
        false
      end

      # Get system information age in seconds
      #
      # @return [Integer, nil] age in seconds or nil if not available
      def info_age
        info = load_info
        return nil if info.empty? || !info[:collected_at]

        collected_at = info[:collected_at]
        current_time - Time.parse(collected_at)
      rescue StandardError => e
        log_error "Failed to get info age: #{e.message}"
        nil
      end

      # Clear cached system information
      #
      # @return [Boolean] true if successful
      def clear_cache
        log_info "Clearing system information cache"
        safe_delete_file(@info_file)
      end

      # Get system information summary for dashboard
      #
      # @return [Hash] summary information
      # rubocop:disable Metrics/MethodLength
      def summary
        info = cached_info
        return {} if info.empty? || info[:error]

        {
          hostname: dig_with_indifferent_access(info, :machine, :hostname),
          os: dig_with_indifferent_access(info, :machine, :os, :name),
          ruby_version: dig_with_indifferent_access(info, :runtime, :ruby_version),
          rails_version: dig_with_indifferent_access(info, :runtime, :rails_version),
          database_adapter: dig_with_indifferent_access(info, :database, :adapter, :name),
          memory_usage: dig_with_indifferent_access(info, :machine, :memory, :usage_percent),
          cpu_load: dig_with_indifferent_access(info, :machine, :load_average, "1min") ||
            dig_with_indifferent_access(info, :machine, :cpu, :load_average, "1min") ||
            dig_with_indifferent_access(info, :machine, :load, :one_minute),
          active_connections: dig_with_indifferent_access(info, :database, :active_connections) ||
            dig_with_indifferent_access(info, :database, :connection_pool, :connections),
          collected_at: info[:collected_at],
          collection_duration: info[:collection_duration]
        }
      rescue StandardError => e
        log_error "Failed to get system info summary: #{e.message}"
        {}
      end
      # rubocop:enable Metrics/MethodLength

      private

      # Check if system information is expired
      #
      # @param info [Hash] system information data
      # @param max_age [Integer] maximum age in seconds
      # @return [Boolean] true if expired
      def info_expired?(info, max_age)
        collected_at = info[:collected_at]
        return true unless collected_at

        (current_time - Time.parse(collected_at)) > max_age
      rescue StandardError => e
        log_error "Failed to check info expiration: #{e.message}"
        true # Assume expired on error
      end

      # Get current time, using Rails method if available
      #
      # @return [Time] current time
      def current_time
        defined?(Time.current) ? Time.current : Time.now
      end

      # Convert all hash keys to strings recursively
      #
      # @param hash [Hash] hash to convert
      # @return [Hash] hash with string keys
      def convert_keys_to_strings(hash)
        return hash unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, value), result|
          string_key = key.to_s
          result[string_key] = if value.is_a?(Hash)
                                 convert_keys_to_strings(value)
                               elsif value.is_a?(Array)
                                 value.map { |v| v.is_a?(Hash) ? convert_keys_to_strings(v) : v }
                               else
                                 value
                               end
        end
      end

      # Convert all hash keys to symbols recursively
      #
      # @param hash [Hash] hash to convert
      # @return [Hash] hash with symbol keys
      def convert_keys_to_symbols(hash)
        return hash unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, value), result|
          symbol_key = key.to_s.to_sym
          result[symbol_key] = if value.is_a?(Hash)
                                 convert_keys_to_symbols(value)
                               elsif value.is_a?(Array)
                                 value.map { |v| v.is_a?(Hash) ? convert_keys_to_symbols(v) : v }
                               else
                                 value
                               end
        end
      end

      # Safe access to nested hash values with indifferent access
      #
      # @param hash [Hash] hash to access
      # @param keys [Array] keys to access
      # @return [Object, nil] value or nil if not found
      def dig_with_indifferent_access(hash, *keys)
        return nil unless hash.is_a?(Hash)

        current = hash
        keys.each do |key|
          key_sym = key.to_s.to_sym
          key_str = key.to_s
          return nil unless current.is_a?(Hash)

          current = current[key_sym] || current[key_str]
          return nil if current.nil?
        end
        current
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
