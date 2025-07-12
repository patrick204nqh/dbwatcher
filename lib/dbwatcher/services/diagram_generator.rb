# frozen_string_literal: true

require_relative "diagram_error_handler"
require_relative "diagram_type_registry"

module Dbwatcher
  module Services
    # Service for generating diagrams from session data
    #
    # Coordinates the process of generating diagrams by:
    # 1. Loading session data
    # 2. Using appropriate analyzers to extract relationships
    # 3. Applying diagram generation strategies
    #
    # @example
    #   generator = DiagramGenerator.new(session_id: "abc123", diagram_type: "database_tables")
    #   result = generator.call
    #   # => { success: true, content: "erDiagram\n...", type: "erDiagram" }
    class DiagramGenerator
      include Dbwatcher::Logging

      # Initialize generator with options
      #
      # @param session_id [String] session ID to analyze
      # @param diagram_type [String] type of diagram to generate
      # @param options [Hash] additional options
      def initialize(session_id:, diagram_type:, options: {})
        @session_id = session_id
        @diagram_type = diagram_type
        @options = options
        @registry = options[:registry] || DiagramTypeRegistry.new
        @logger = options[:logger] || Rails.logger
      end

      # Generate diagram
      #
      # @return [Hash] diagram generation result
      def call
        log_info("Generating diagram of type #{@diagram_type} for session #{@session_id}")

        start_time = Time.current
        result = generate_diagram

        duration_ms = ((Time.current - start_time) * 1000).round(2)
        log_info("Diagram generation completed in #{duration_ms}ms", {
                   session_id: @session_id,
                   diagram_type: @diagram_type,
                   success: result[:success]
                 })

        result
      rescue StandardError => e
        log_error("Diagram generation failed: #{e.message}", error_context)
        error_result("Diagram generation failed: #{e.message}")
      end

      private

      # Generate diagram based on configuration
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

        log_debug("Generated dataset with #{dataset.entities.size} entities and " \
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
        log_warn("Could not load session #{@session_id}: #{e.message}")
        nil
      end

      # Build error context for error handler
      #
      # @return [Hash] error context
      def error_context
        {
          session_id: @session_id,
          diagram_type: @diagram_type,
          timestamp: Time.now
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
          generated_at: Time.now.iso8601
        }
      end
    end
  end
end
