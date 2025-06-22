# frozen_string_literal: true

require_relative "diagram_cache"
require_relative "diagram_error_handler"
require_relative "diagram_type_registry"
require_relative "mermaid_syntax_builder"
require_relative "diagram_strategies/base_diagram_strategy"
require_relative "diagram_strategies/erd_diagram_strategy"
require_relative "diagram_strategies/flowchart_diagram_strategy"
require_relative "analyzers/schema_relationship_analyzer"
require_relative "analyzers/model_association_analyzer"

module Dbwatcher
  module Services
    # Orchestrator for diagram generation using strategy pattern
    #
    # This service coordinates diagram generation by delegating to appropriate
    # strategy classes while providing caching, error handling, and observability.
    #
    # @example
    #   generator = DiagramGenerator.new(session_id, 'database_tables')
    #   result = generator.call
    #   # => { content: "erDiagram\n    USERS ||--o{ ORDERS : user_id", type: 'erDiagram' }
    class DiagramGenerator < BaseService
      attr_reader :session_id, :diagram_type, :registry, :cache, :error_handler

      # Initialize with session id, diagram type, and optional dependencies
      #
      # @param session_id [String] session identifier
      # @param diagram_type [String] type of diagram to generate
      # @param dependencies [Hash] optional dependency injection
      # @option dependencies [DiagramTypeRegistry] :registry type registry
      # @option dependencies [DiagramCache] :cache caching layer
      # @option dependencies [DiagramErrorHandler] :error_handler error handler
      # @option dependencies [Logger] :logger logger instance
      def initialize(session_id, diagram_type = "database_tables", dependencies = {})
        @session_id = session_id
        @diagram_type = diagram_type
        @registry = dependencies[:registry] || DiagramTypeRegistry.new
        @cache = dependencies[:cache] || DiagramCache.new
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
          # Check cache first for performance
          cached_result = @cache.get(cache_key)
          if cached_result
            log_cache_hit(start_time)
            return cached_result
          end

          # Generate new diagram using strategy
          result = generate_diagram_using_strategy

          # Cache successful results
          cache_result(result) if result[:success]

          log_generation_completion(start_time, result)
          result
        rescue StandardError => e
          # Use new comprehensive error handling for all errors
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
        registry = DiagramTypeRegistry.new
        registry.available_types_with_metadata
      end

      private

      # Generate diagram using appropriate strategy
      #
      # @return [Hash] diagram generation result
      def generate_diagram_using_strategy
        # Validate diagram type first
        unless @registry.type_exists?(@diagram_type)
          raise DiagramTypeRegistry::UnknownTypeError, "Invalid diagram type: #{@diagram_type}"
        end

        strategy = @registry.create_strategy(@diagram_type, strategy_dependencies)
        strategy.generate(@session_id)
      end

      # Build strategy dependencies
      #
      # @return [Hash] dependencies for strategy injection
      def strategy_dependencies
        {
          logger: @logger,
          config: strategy_config
        }
      end

      # Get strategy-specific configuration
      #
      # @return [Hash] configuration for the strategy
      def strategy_config
        # Could be loaded from Rails configuration, database, etc.
        {}
      end

      # Build cache key for diagram
      #
      # @return [String] cache key
      def cache_key
        "diagram:#{@session_id}:#{@diagram_type}"
      end

      # Cache successful result
      #
      # @param result [Hash] generation result
      def cache_result(result)
        @cache.set(cache_key, result)
      rescue StandardError => e
        @logger.warn "Failed to cache result: #{e.message}"
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

      # Log cache hit
      #
      # @param start_time [Time] operation start time
      def log_cache_hit(start_time)
        duration = Time.current - start_time
        @logger.info("Cache hit for session #{@session_id} type #{@diagram_type} in #{(duration * 1000).round(2)}ms")
      end

      # Log generation completion
      #
      # @param start_time [Time] operation start time
      # @param result [Hash] generation result
      def log_generation_completion(start_time, result)
        duration = Time.current - start_time
        @logger.info("Diagram generation completed for session #{@session_id} type #{@diagram_type} success=#{result[:success]} in #{(duration * 1000).round(2)}ms")
      end
    end
  end
end
