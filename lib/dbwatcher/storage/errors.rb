# frozen_string_literal: true

module Dbwatcher
  module Storage
    # Base storage error class
    #
    # All storage-related errors inherit from this class to provide
    # consistent error handling across the storage module.
    class StorageError < StandardError; end

    # Raised when validation fails on storage operations
    class ValidationError < StorageError; end

    # Raised when a requested session cannot be found
    class SessionNotFoundError < StorageError; end

    # Raised when a requested query cannot be found
    class QueryNotFoundError < StorageError; end

    # Raised when a requested table cannot be found
    class TableNotFoundError < StorageError; end

    # Raised when storage data becomes corrupted
    class CorruptedDataError < StorageError; end

    # Raised when storage permissions are insufficient
    class PermissionError < StorageError; end

    # Provides error handling capabilities for storage operations
    #
    # This module can be included in storage classes to provide
    # standardized error handling and logging capabilities.
    #
    # @example
    #   class MyStorage
    #     include ErrorHandler
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
        warn "Storage #{operation} failed: #{e.message}"
        raise StorageError, "#{operation} failed: #{e.message}"
      end

      private

      # Logs an error message with exception details
      #
      # @param message [String] the error message
      # @param error [Exception] the exception that occurred
      # @return [void]
      def log_error(message, error)
        warn "#{message}: #{error.message}"
      end
    end
  end
end
