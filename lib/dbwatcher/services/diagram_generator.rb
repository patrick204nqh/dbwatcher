# frozen_string_literal: true

require_relative "diagram_error_handler"
require_relative "diagram_type_registry"

module Dbwatcher
  module Services
    # Orchestrator for diagram generation using strategy pattern
    #
    # This service coordinates diagram generation by delegating to appropriate
    # analyzer and strategy classes with clean error handling.
    #
    # @example
    #   generator = DiagramGenerator.new(session_id, 'database_tables')
    #   result = generator.call
    #   # => { content: "erDiagram\n    USERS ||--o{ ORDERS : user_id", type: 'erDiagram' }
    class DiagramGenerator < BaseService
      attr_reader :session_id, :diagram_type, :registry, :error_handler, :logger

      # Initialize with session id and diagram type
      #
      # @param session_id [String] session identifier
      # @param diagram_type [String] type of diagram to generate
      # @param dependencies [Hash] optional dependency injection
      # @option dependencies [DiagramTypeRegistry] :registry type registry
      # @option dependencies [DiagramErrorHandler] :error_handler error handler
      # @option dependencies [Logger] :logger logger instance
      def initialize(session_id, diagram_type = "database_tables", dependencies = {})
        @session_id = session_id
        @diagram_type = diagram_type
        @registry = dependencies[:registry] || DiagramTypeRegistry.new
        @error_handler = dependencies[:error_handler] || DiagramErrorHandler.new
        @logger = dependencies[:logger] || Rails.logger || Logger.new($stdout)
        super()
      end

      # Generate diagram for session
      #
      # @return [Hash] diagram data with content and type
      def call
        @logger.info("Generating diagram for session #{@session_id} with type #{@diagram_type}")
        start_time = Time.current

        begin
          result = generate_diagram
          log_completion(start_time, result)
          result
        rescue StandardError => e
          @error_handler.handle_generation_error(e, error_context)
        end
      end

      # Get available diagram types with metadata
      #
      # @return [Hash] diagram types with metadata
      def available_types
        @registry.available_types_with_metadata
      end

      # Get available diagram types (class method for backward compatibility)
      #
      # @return [Hash] diagram types with metadata
      def self.available_types
        DiagramTypeRegistry.new.available_types_with_metadata
      end

      private

      # Generate diagram using standardized analyzer-to-strategy flow
      #
      # @return [Hash] diagram generation result
      def generate_diagram
        # Validate diagram type
        unless @registry.type_exists?(@diagram_type)
          raise DiagramTypeRegistry::UnknownTypeError, "Invalid diagram type: #{@diagram_type}"
        end

        # Load session
        session = load_session
        return error_result("Session not found") unless session

        # Create analyzer and generate dataset
        analyzer = @registry.create_analyzer(@diagram_type, session)
        dataset = analyzer.call

        @logger.debug("Generated dataset with #{dataset.entities.size} entities and " \
                      "#{dataset.relationships.size} relationships")

        # Create strategy and generate diagram from dataset
        strategy = @registry.create_strategy(@diagram_type)
        strategy.generate_from_dataset(dataset)
      end

      # Load session for analysis
      #
      # @return [Object] session object
      def load_session
        Dbwatcher::Storage.sessions.find(@session_id)
      rescue StandardError => e
        @logger.warn("Could not load session #{@session_id}: #{e.message}")
        nil
      end

      # Build error context for error handler
      #
      # @return [Hash] error context
      def error_context
        {
          session_id: @session_id,
          diagram_type: @diagram_type,
          timestamp: Time.current
        }
      end

      # Create error result
      #
      # @param message [String] error message
      # @return [Hash] error result
      def error_result(message)
        {
          success: false,
          error: message,
          content: nil,
          type: nil,
          generated_at: Time.current.iso8601
        }
      end

      # Log generation completion
      #
      # @param start_time [Time] operation start time
      # @param result [Hash] generation result
      def log_completion(start_time, result)
        duration = Time.current - start_time
        success = result[:success] || false
        @logger.info("Diagram generation completed for session #{@session_id} type #{@diagram_type} " \
                     "in #{(duration * 1000).round(2)}ms - Success: #{success}")
      end
    end
  end
end
