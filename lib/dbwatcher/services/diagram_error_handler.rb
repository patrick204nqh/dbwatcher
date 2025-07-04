# frozen_string_literal: true

module Dbwatcher
  module Services
    # Centralized error handling for diagram generation
    #
    # Provides consistent error categorization, logging, and response formatting
    # for all diagram generation failures with recovery strategies.
    #
    # @example
    #   handler = DiagramErrorHandler.new
    #   response = handler.handle_generation_error(error, context)
    #   # => { success: false, error_code: 'DIAGRAM_001', message: '...', recoverable: false }
    class DiagramErrorHandler
      # Custom error class for diagram generation failures
      class DiagramGenerationError < StandardError
        attr_reader :error_code, :context, :original_error

        def initialize(message, error_code: nil, context: {}, original_error: nil)
          super(message)
          @error_code = error_code
          @context = context
          @original_error = original_error
        end
      end

      # Error code mapping for consistent error identification
      ERROR_CODES = {
        session_not_found: "DIAGRAM_001",
        invalid_diagram_type: "DIAGRAM_002",
        syntax_validation_failed: "DIAGRAM_003",
        generation_timeout: "DIAGRAM_004",
        insufficient_data: "DIAGRAM_005",
        analyzer_error: "DIAGRAM_006",
        cache_error: "DIAGRAM_007",
        system_error: "DIAGRAM_099"
      }.freeze

      # Initialize error handler with configuration
      #
      # @param config [Hash] error handler configuration
      # @option config [Logger] :logger logger instance
      # @option config [Boolean] :include_backtrace include backtrace in logs
      # @option config [Integer] :backtrace_lines number of backtrace lines to log
      def initialize(config = {})
        @config = default_config.merge(config)
        @logger = @config[:logger] || default_logger
      end

      # Handle diagram generation error with categorization and logging
      #
      # @param error [Exception] the original error
      # @param context [Hash] additional context information
      # @return [Hash] formatted error response
      def handle_generation_error(error, context = {})
        error_info = categorize_error(error, context)
        log_error(error_info)

        # Return user-friendly error response
        create_error_response(error_info)
      end

      # Check if an error type is recoverable
      #
      # @param error_code [String] error code
      # @return [Boolean] true if error is recoverable
      def recoverable_error?(error_code)
        recoverable_codes = [
          ERROR_CODES[:syntax_validation_failed],
          ERROR_CODES[:generation_timeout],
          ERROR_CODES[:insufficient_data],
          ERROR_CODES[:cache_error]
        ]
        recoverable_codes.include?(error_code)
      end

      private

      # Default configuration
      #
      # @return [Hash] default configuration
      def default_config
        {
          include_backtrace: true,
          backtrace_lines: 5
        }
      end

      # Default logger when no logger is provided
      #
      # @return [Logger] default logger instance
      def default_logger
        # Use Rails logger if available, otherwise create a simple logger
        if defined?(Rails) && Rails.respond_to?(:logger)
          Rails.logger
        else
          require "logger"
          Logger.new($stdout)
        end
      end

      # Categorize error based on type and context
      #
      # @param error [Exception] the original error
      # @param context [Hash] error context
      # @return [Hash] categorized error information
      def categorize_error(error, context)
        # Check for session not found errors first
        if error.message.include?("Session") && error.message.include?("not found")
          return {
            type: :session_not_found,
            code: ERROR_CODES[:session_not_found],
            message: "Session not found: #{context[:session_id]}",
            recoverable: false,
            original_error: error,
            user_message: "The requested session could not be found. Please verify the session ID."
          }
        end

        case error
        when ArgumentError
          if error.message.include?("Unknown diagram type") || error.message.include?("Invalid diagram type")
            {
              type: :invalid_diagram_type,
              code: ERROR_CODES[:invalid_diagram_type],
              message: "Invalid diagram type: #{context[:diagram_type]}",
              recoverable: false,
              original_error: error,
              user_message: "The requested diagram type is not supported."
            }
          else
            categorize_generic_error(error, context)
          end
        when StandardError
          if error.message.include?("syntax") || error.message.include?("Mermaid")
            {
              type: :syntax_validation_failed,
              code: ERROR_CODES[:syntax_validation_failed],
              message: "Diagram syntax validation failed: #{error.message}",
              recoverable: true,
              original_error: error,
              user_message: "There was an issue generating the diagram syntax. Please try again."
            }
          elsif error.message.include?("timeout") || error.is_a?(Timeout::Error)
            {
              type: :generation_timeout,
              code: ERROR_CODES[:generation_timeout],
              message: "Diagram generation timed out",
              recoverable: true,
              original_error: error,
              user_message: "Diagram generation took too long. Please try again with a smaller dataset."
            }
          elsif error.message.include?("No") && error.message.include?("found")
            {
              type: :insufficient_data,
              code: ERROR_CODES[:insufficient_data],
              message: "Insufficient data for diagram generation: #{error.message}",
              recoverable: true,
              original_error: error,
              user_message: "Not enough data available to generate the diagram."
            }
          elsif error.message.include?("cache") || error.message.include?("Cache")
            {
              type: :cache_error,
              code: ERROR_CODES[:cache_error],
              message: "Cache operation failed: #{error.message}",
              recoverable: true,
              original_error: error,
              user_message: "A temporary caching issue occurred. The diagram was still generated."
            }
          else
            categorize_generic_error(error, context)
          end
        else
          categorize_generic_error(error, context)
        end
      end

      # Categorize generic/unknown errors
      #
      # @param error [Exception] the original error
      # @param context [Hash] error context
      # @return [Hash] categorized error information
      def categorize_generic_error(error, _context)
        {
          type: :system_error,
          code: ERROR_CODES[:system_error],
          message: "Unexpected error during diagram generation: #{error.class.name}",
          recoverable: false,
          original_error: error,
          user_message: "An unexpected error occurred. Please try again or contact support."
        }
      end

      # Log error with appropriate level and detail
      #
      # @param error_info [Hash] categorized error information
      def log_error(error_info)
        log_data = {
          error_code: error_info[:code],
          error_type: error_info[:type],
          message: error_info[:message],
          recoverable: error_info[:recoverable],
          original_error_class: error_info[:original_error]&.class&.name
        }

        # Add backtrace if configured and available
        if @config[:include_backtrace] && error_info[:original_error]&.backtrace
          log_data[:backtrace] = error_info[:original_error].backtrace.first(@config[:backtrace_lines])
        end

        # Log at appropriate level based on recoverability
        if error_info[:recoverable]
          @logger.warn "Recoverable diagram generation error: #{error_info[:message]} (#{error_info[:code]})"
        else
          @logger.error "Non-recoverable diagram generation error: #{error_info[:message]} (#{error_info[:code]})"
        end
      end

      # Create formatted error response
      #
      # @param error_info [Hash] categorized error information
      # @return [Hash] formatted error response
      def create_error_response(error_info)
        {
          success: false,
          error: error_info[:user_message] || error_info[:message],
          error_code: error_info[:code],
          error_type: error_info[:type],
          message: error_info[:user_message] || error_info[:message],
          recoverable: error_info[:recoverable],
          timestamp: Time.now.iso8601,
          content: nil,
          type: nil
        }
      end
    end
  end
end
