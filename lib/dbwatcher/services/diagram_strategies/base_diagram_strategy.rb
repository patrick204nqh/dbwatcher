# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Abstract base class for diagram generation strategies
      #
      # Defines the common interface and shared behavior for all diagram generation
      # strategies. Subclasses must implement the generate method and metadata methods.
      #
      # @example
      #   class CustomDiagramStrategy < BaseDiagramStrategy
      #     def generate(session_id)
      #       # Implementation specific logic
      #     end
      #   end
      class BaseDiagramStrategy
        attr_reader :syntax_builder, :config, :logger

        # Initialize strategy with dependencies
        #
        # @param dependencies [Hash] injected dependencies
        # @option dependencies [Object] :syntax_builder Mermaid syntax builder
        # @option dependencies [Hash] :config strategy configuration
        # @option dependencies [Logger] :logger logger instance
        def initialize(dependencies = {})
          @syntax_builder = dependencies[:syntax_builder] || create_default_syntax_builder
          @config = default_config.merge(dependencies[:config] || {})
          @logger = dependencies[:logger] || Rails.logger || Logger.new($stdout)
        end

        # Generate diagram for given session (legacy method)
        #
        # @param session_id [String] session identifier
        # @return [Hash] diagram generation result
        # @raise [NotImplementedError] if not implemented by subclass
        def generate(session_id)
          raise NotImplementedError, "Subclasses must implement generate method"
        end

        # Generate diagram from standardized dataset (new method)
        #
        # @param dataset [DiagramData::DiagramDataset] standardized dataset
        # @return [Hash] diagram generation result
        def generate_from_dataset(dataset)
          @logger.info("Generating diagram from dataset with #{dataset.entities.size} entities and #{dataset.relationships.size} relationships")
          start_time = Time.current

          begin
            # Validate dataset meets requirements
            validation_errors = validate_dataset(dataset)
            if validation_errors.any?
              return error_response("Dataset validation failed: #{validation_errors.join("; ")}")
            end

            # Generate diagram using dataset
            result = render_diagram(dataset)

            log_operation_completion("diagram generation", Time.current - start_time, {
                                       entities_count: dataset.entities.size,
                                       relationships_count: dataset.relationships.size
                                     })

            result
          rescue StandardError => e
            @logger.error("Diagram generation failed: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
            error_response("Diagram generation failed: #{e.message}")
          end
        end

        # Define what data requirements this strategy needs
        #
        # @return [Hash] data requirements specification
        def data_requirements
          {
            minimum_entities: 0,
            minimum_relationships: 0,
            required_entity_types: [],
            required_relationship_types: [],
            optional_entity_types: [],
            optional_relationship_types: []
          }
        end

        # Validate if dataset meets requirements
        #
        # @param dataset [DiagramData::DiagramDataset] dataset to validate
        # @return [Array<String>] array of validation errors (empty if valid)
        def validate_dataset(dataset)
          errors = []

          unless dataset.is_a?(Dbwatcher::Services::DiagramData::DiagramDataset)
            errors << "Invalid dataset type: expected DiagramDataset, got #{dataset.class}"
            return errors
          end

          errors << "Dataset is invalid: #{dataset.validation_errors.join(", ")}" unless dataset.valid?

          reqs = data_requirements

          # Check minimum entities
          if dataset.entities.size < reqs[:minimum_entities]
            errors << "Insufficient entities: #{dataset.entities.size} < #{reqs[:minimum_entities]}"
          end

          # Check minimum relationships
          if dataset.relationships.size < reqs[:minimum_relationships]
            errors << "Insufficient relationships: #{dataset.relationships.size} < #{reqs[:minimum_relationships]}"
          end

          # Check required entity types
          entity_types = dataset.entities.values.map(&:type).uniq
          missing_entity_types = reqs[:required_entity_types] - entity_types
          errors << "Missing required entity types: #{missing_entity_types.join(", ")}" if missing_entity_types.any?

          # Check required relationship types
          relationship_types = dataset.relationships.map(&:type).uniq
          missing_relationship_types = reqs[:required_relationship_types] - relationship_types
          if missing_relationship_types.any?
            errors << "Missing required relationship types: #{missing_relationship_types.join(", ")}"
          end

          errors
        end

        # Get strategy metadata (abstract method)
        #
        # @return [Hash] strategy metadata including name, description, features
        # @raise [NotImplementedError] if not implemented by subclass
        def metadata
          {
            name: strategy_name,
            description: strategy_description,
            supported_features: supported_features,
            configuration: configurable_options,
            mermaid_type: mermaid_diagram_type,
            data_requirements: data_requirements
          }
        end

        # Check if strategy can handle given session
        #
        # @param session_id [String] session identifier
        # @return [Boolean] true if strategy can handle session
        def can_handle?(session_id)
          session = load_session_with_validation(session_id)
          session && has_required_data?(session)
        rescue StandardError => e
          @logger.warn "Strategy cannot handle session #{session_id}: #{e.message}"
          false
        end

        # Check if strategy can handle given dataset
        #
        # @param dataset [DiagramData::DiagramDataset] dataset to check
        # @return [Boolean] true if strategy can handle dataset
        def can_handle_dataset?(dataset)
          validate_dataset(dataset).empty?
        rescue StandardError => e
          @logger.warn "Strategy cannot handle dataset: #{e.message}"
          false
        end

        protected

        # Render diagram from dataset (abstract method)
        #
        # @param dataset [DiagramData::DiagramDataset] standardized dataset
        # @return [Hash] diagram generation result
        # @raise [NotImplementedError] if not implemented by subclass
        def render_diagram(dataset)
          raise NotImplementedError, "Subclasses must implement render_diagram method"
        end

        # Build empty diagram with message
        #
        # @param message [String] message to display in empty diagram
        # @param diagram_type [String] type of empty diagram to create
        # @return [Hash] empty diagram result
        def build_empty_diagram(message, diagram_type = nil)
          diagram_type ||= mermaid_diagram_type
          content = @syntax_builder.build_empty_diagram(message, diagram_type)
          success_response(content, diagram_type)
        end

        # Load session with validation
        #
        # @param session_id [String] session identifier
        # @return [Object] session object
        # @raise [StandardError] if session not found
        def load_session_with_validation(session_id)
          session = Dbwatcher::Storage.sessions.find(session_id)
          raise StandardError, "Session #{session_id} not found" unless session

          session
        rescue StandardError => e
          @logger.error("Failed to load session for #{session_id}: #{e.message}")
          raise
        end

        # Check if session has required data for this strategy
        #
        # @param session [Object] session object
        # @return [Boolean] true if session has required data
        def has_required_data?(session)
          # Default implementation - subclasses should override
          session && !session.empty?
        end

        # Create success response
        #
        # @param content [String] diagram content
        # @param type [String] diagram type
        # @return [Hash] success response
        def success_response(content, type)
          {
            success: true,
            content: content,
            type: type,
            generated_at: Time.current.iso8601
          }
        end

        # Create error response
        #
        # @param message [String] error message
        # @return [Hash] error response
        def error_response(message)
          {
            success: false,
            error: true,
            message: message,
            content: nil,
            type: nil,
            timestamp: Time.current.iso8601
          }
        end

        # Log strategy operation start
        #
        # @param operation [String] operation description
        # @param context [Hash] additional context
        def log_operation_start(operation, _context = {})
          @logger.info("Strategy operation started: #{operation} by #{self.class.name}")
        end

        # Log strategy operation completion
        #
        # @param operation [String] operation description
        # @param duration [Float] operation duration in seconds
        # @param context [Hash] additional context
        def log_operation_completion(operation, duration, _context = {})
          @logger.info("Strategy operation completed: #{operation} by #{self.class.name} in #{(duration * 1000).round(2)}ms")
        end

        # Measure operation duration
        #
        # @yield block to measure
        # @return [Array] result and duration
        def measure_duration
          start_time = Time.current
          result = yield
          duration = Time.current - start_time
          [result, duration]
        end

        private

        # Default configuration for strategies
        #
        # @return [Hash] default configuration
        def default_config
          {
            max_nodes: 100,
            max_edges: 200,
            timeout_seconds: 30,
            enable_caching: true,
            validate_output: true
          }
        end

        # Create default syntax builder
        #
        # @return [MermaidSyntaxBuilder] syntax builder instance
        def create_default_syntax_builder
          Dbwatcher::Services::MermaidSyntaxBuilder.new
        end

        # Abstract methods that subclasses must implement

        # Get strategy name
        #
        # @return [String] human-readable strategy name
        # @raise [NotImplementedError] if not implemented by subclass
        def strategy_name
          raise NotImplementedError, "Subclasses must implement strategy_name"
        end

        # Get strategy description
        #
        # @return [String] strategy description
        # @raise [NotImplementedError] if not implemented by subclass
        def strategy_description
          raise NotImplementedError, "Subclasses must implement strategy_description"
        end

        # Get supported features
        #
        # @return [Array<Symbol>] supported features
        def supported_features
          []
        end

        # Get configurable options
        #
        # @return [Hash] configurable options with defaults
        def configurable_options
          {}
        end

        # Get Mermaid diagram type
        #
        # @return [String] Mermaid diagram type
        # @raise [NotImplementedError] if not implemented by subclass
        def mermaid_diagram_type
          raise NotImplementedError, "Subclasses must implement mermaid_diagram_type"
        end
      end
    end
  end
end
