# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Abstract base class for diagram generation strategies
      #
      # Defines the common interface and shared behavior for all diagram generation
      # strategies. Subclasses must implement the render_diagram method.
      class BaseDiagramStrategy
        attr_reader :syntax_builder, :logger

        # Initialize strategy with dependencies
        #
        # @param dependencies [Hash] injected dependencies
        # @option dependencies [Object] :syntax_builder Mermaid syntax builder
        # @option dependencies [Logger] :logger logger instance
        def initialize(dependencies = {})
          @syntax_builder = dependencies[:syntax_builder] || create_default_syntax_builder
          @logger = dependencies[:logger] || Rails.logger || Logger.new($stdout)
        end

        # Generate diagram from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [Hash] diagram generation result
        def generate_from_dataset(dataset)
          @logger.info("Generating diagram from dataset with #{dataset.entities.size} entities and #{dataset.relationships.size} relationships")
          start_time = Time.current

          begin
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

        # Get strategy metadata (abstract method)
        #
        # @return [Hash] strategy metadata including name, description
        # @raise [NotImplementedError] if not implemented by subclass
        def metadata
          {
            name: strategy_name,
            description: strategy_description,
            mermaid_type: mermaid_diagram_type
          }
        end

        protected

        # Render diagram from dataset (abstract method)
        #
        # @param dataset [Dataset] standardized dataset
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
            generated_at: Time.current,
            metadata: {
              strategy: self.class.name
            }
          }
        end

        # Create error response
        #
        # @param message [String] error message
        # @return [Hash] error response
        def error_response(message)
          {
            success: false,
            error: message,
            content: nil,
            type: nil,
            generated_at: Time.current,
            metadata: {
              strategy: self.class.name
            }
          }
        end

        # Log operation completion
        #
        # @param operation [String] operation name
        # @param duration [Float] operation duration in seconds
        # @param context [Hash] additional context
        def log_operation_completion(operation, duration, context = {})
          @logger.info("Strategy operation completed: #{operation} by #{self.class.name} in #{(duration * 1000).round(2)}ms")
        end

        # Create default syntax builder
        #
        # @return [MermaidSyntaxBuilder] syntax builder instance
        def create_default_syntax_builder
          Dbwatcher::Services::MermaidSyntaxBuilder.new
        end

        # Strategy metadata methods (abstract)

        def strategy_name
          raise NotImplementedError, "Subclasses must implement strategy_name"
        end

        def strategy_description
          raise NotImplementedError, "Subclasses must implement strategy_description"
        end

        def mermaid_diagram_type
          raise NotImplementedError, "Subclasses must implement mermaid_diagram_type"
        end
      end
    end
  end
end
