# frozen_string_literal: true

module Dbwatcher
  module Storage
    class StorageError < StandardError; end
    class SessionNotFoundError < StorageError; end
    class QueryNotFoundError < StorageError; end
    class TableNotFoundError < StorageError; end

    module ErrorHandler
      def safe_operation(operation_name, default_value = nil, &block)
        block.call
      rescue JSON::ParserError => e
        log_error("JSON parsing failed in #{operation_name}", e)
        default_value
      rescue StandardError => e
        log_error("#{operation_name} failed", e)
        default_value
      end

      def with_error_handling(operation, &block)
        block.call
      rescue StandardError => e
        warn "Storage #{operation} failed: #{e.message}"
        raise StorageError, "#{operation} failed: #{e.message}"
      end

      private

      def log_error(message, error)
        warn "#{message}: #{error.message}"
      end
    end
  end
end
