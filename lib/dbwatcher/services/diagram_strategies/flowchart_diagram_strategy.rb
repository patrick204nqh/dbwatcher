# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating flowchart diagrams from model associations
      #
      # Handles flowchart diagram generation by analyzing ActiveRecord model
      # associations and converting them to Mermaid flowchart syntax.
      #
      # @example
      #   strategy = FlowchartDiagramStrategy.new
      #   result = strategy.generate(session_id)
      #   # => { success: true, content: "flowchart LR\n    User --> Post...", type: "flowchart" }
      class FlowchartDiagramStrategy < BaseDiagramStrategy
        # Initialize flowchart strategy with dependencies
        #
        # @param dependencies [Hash] injected dependencies
        # @option dependencies [MermaidSyntaxBuilder] :syntax_builder Mermaid syntax builder
        # @option dependencies [Hash] :config strategy configuration
        # @option dependencies [Logger] :logger logger instance
        def initialize(dependencies = {})
          super
          @analyzer_class = dependencies[:analyzer_class] ||
                            Dbwatcher::Services::Analyzers::ModelAssociationAnalyzer
        end

        # Generate flowchart diagram for session (legacy method)
        #
        # @param session_id [String] session identifier
        # @return [Hash] diagram generation result
        def generate(session_id)
          operation = "Flowchart diagram generation"
          log_operation_start(operation, session_id: session_id)

          result, duration = measure_duration do
            generate_flowchart_diagram(session_id)
          end

          log_operation_completion(operation, duration, {
                                     session_id: session_id,
                                     success: result[:success],
                                     association_count: count_associations_in_content(result[:content]),
                                     node_count: count_nodes_in_content(result[:content])
                                   })

          result
        end

        # Define data requirements for flowchart diagrams
        #
        # @return [Hash] data requirements specification
        def data_requirements
          {
            minimum_entities: 1,
            minimum_relationships: 0,
            required_entity_types: [],
            required_relationship_types: [],
            optional_entity_types: %w[model table],
            optional_relationship_types: %w[has_many belongs_to has_one has_and_belongs_to_many through polymorphic]
          }
        end

        protected

        # Render flowchart diagram from standardized dataset
        #
        # @param dataset [DiagramData::DiagramDataset] standardized dataset
        # @return [Hash] diagram generation result
        def render_diagram(dataset)
          @logger.debug "Rendering flowchart diagram from dataset with #{dataset.entities.size} entities and #{dataset.relationships.size} relationships"

          # Generate diagram content directly from dataset
          content = if dataset.relationships.empty? && dataset.entities.empty?
                      @syntax_builder.build_empty_flowchart("No model associations or entities found")
                    elsif dataset.relationships.empty?
                      # Show isolated nodes if no relationships but entities exist
                      @syntax_builder.build_flowchart_with_nodes(dataset.entities.values, flowchart_generation_options)
                    else
                      @syntax_builder.build_flowchart_diagram_from_dataset(dataset, flowchart_generation_options)
                    end

          success_response(content, "flowchart")
        end

        # Check if session has required data for flowchart generation
        #
        # @param session [Object] session object
        # @return [Boolean] true if session has model association data
        def has_required_data?(session)
          return false unless session

          # Check if session has data that could contain model information
          (session.respond_to?(:tables) && session.tables&.any?) ||
            (session.respond_to?(:queries) && session.queries&.any?)
        end

        private

        # Generate flowchart diagram content (legacy method)
        #
        # @param session_id [String] session identifier
        # @return [Hash] generation result
        def generate_flowchart_diagram(session_id)
          session = load_session_with_validation(session_id)

          # Analyze model associations
          analyzer = @analyzer_class.new(session)
          associations = analyzer.call

          @logger.debug("Analyzed associations for session #{session_id}: #{associations.size} associations")

          # Generate diagram content
          content = if associations.empty?
                      @syntax_builder.build_empty_flowchart("No model associations found in this session")
                    else
                      @syntax_builder.build_flowchart_diagram(associations, flowchart_generation_options)
                    end

          success_response(content, "flowchart")
        end

        # Get flowchart-specific generation options
        #
        # @return [Hash] generation options for flowchart
        def flowchart_generation_options
          {
            layout_direction: @config[:layout_direction] || "TB",
            show_methods: @config[:show_methods] || false,
            max_models: @config[:max_models] || 30,
            apply_styling: @config[:apply_styling] != false,
            include_isolated_nodes: @config[:include_isolated_nodes] != false,
            show_legend: @config[:show_legend] == true
          }
        end

        # Count associations in generated content for metrics
        #
        # @param content [String] generated diagram content
        # @return [Integer] number of associations found
        def count_associations_in_content(content)
          return 0 unless content.is_a?(String)

          # Count flowchart edge lines (lines with arrows)
          content.scan(/\s+\w+\s*-->.*\w+/).size
        end

        # Count nodes in generated content for metrics
        #
        # @param content [String] generated diagram content
        # @return [Integer] number of nodes found
        def count_nodes_in_content(content)
          return 0 unless content.is_a?(String)

          # Count flowchart node definitions (lines with square brackets)
          content.scan(/\s+\w+\[.*\]/).size
        end

        # Count association types for debugging
        #
        # @param associations [Array<Hash>] model associations
        # @return [Hash] count by association type
        def count_association_types(associations)
          return {} unless associations.is_a?(Array)

          type_counts = Hash.new(0)
          associations.each do |assoc|
            type = assoc[:association_type] || assoc[:type] || "unknown"
            type_counts[type] += 1
          end
          type_counts
        end

        # Strategy metadata methods

        def strategy_name
          "Model Associations"
        end

        def strategy_description
          "Flowchart diagram showing ActiveRecord model relationships and associations"
        end

        def supported_features
          %w[
            has_many
            belongs_to
            has_one
            has_and_belongs_to_many
            polymorphic_associations
            through_associations
            isolated_models
          ]
        end

        def configurable_options
          {
            layout_direction: {
              type: "string",
              default: "LR",
              options: %w[LR TD RL BT],
              description: "Direction of flowchart layout (LR=left-right, TD=top-down, etc.)"
            },
            show_methods: {
              type: "boolean",
              default: false,
              description: "Include association method names in the diagram"
            },
            max_models: {
              type: "integer",
              default: 30,
              description: "Maximum number of models to include"
            },
            apply_styling: {
              type: "boolean",
              default: true,
              description: "Apply default styling to diagram elements"
            },
            include_isolated_nodes: {
              type: "boolean",
              default: true,
              description: "Include models that have no associations with other models"
            },
            show_legend: {
              type: "boolean",
              default: false,
              description: "Include a legend in the diagram"
            }
          }
        end

        def mermaid_diagram_type
          "flowchart"
        end
      end
    end
  end
end
