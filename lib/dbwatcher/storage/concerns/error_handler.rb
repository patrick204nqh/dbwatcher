# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Concerns
      # Provides standardized error handling capabilities for storage classes
      #
      # This concern can be included in storage classes to provide consistent
      # error handling patterns, logging, and recovery mechanisms.
      #
      # @example
      #   class MyStorage < BaseStorage
      #     include Concerns::ErrorHandler
      #
      #     def risky_operation
      #       safe_operation("my operation") do
      #         # potentially failing code
      #       end
      #     end
      #   end
      module ErrorHandler
        # Executes a block with error handling and optional default return value
        #
        # @param operation_name [String] description of the operation for logging
        # @param default_value [Object] value to return if operation fails
        # @yield [] the block to execute safely
        # @return [Object] the result of the block or default_value on error
        def safe_operation(operation_name, default_value = nil, &block)
          block.call
        rescue JSON::ParserError => e
          log_error("JSON parsing failed in #{operation_name}", e)
          default_value
        rescue Errno::ENOENT => e
          log_error("File not found in #{operation_name}", e)
          default_value
        rescue Errno::EACCES => e
          log_error("Permission denied in #{operation_name}", e)
          raise StorageError, "Permission denied: #{e.message}"
        rescue StandardError => e
          log_error("#{operation_name} failed", e)
          default_value
        end

        # Executes a block with error handling that raises StorageError on failure
        #
        # @param operation [String] description of the operation
        # @yield [] the block to execute
        # @return [Object] the result of the block
        # @raise [StorageError] if the operation fails
        def with_error_handling(operation, &block)
          block.call
        rescue StandardError => e
          error_message = "Storage #{operation} failed: #{e.message}"
          log_error(error_message, e)
          raise StorageError, error_message
        end

        private

        # Logs an error message with exception details
        #
        # @param message [String] the error message
        # @param error [Exception] the exception that occurred
        # @return [void]
        def log_error(message, error)
          if defined?(Rails) && Rails.logger
            Rails.logger.warn("#{message}: #{error.message}")
          else
            warn "#{message}: #{error.message}"
          end
        end
      end
    end
  end
end
