# frozen_string_literal: true

require "set"
require "digest"

module Dbwatcher
  module Services
    # Builder for generating validated Mermaid diagram syntax
    #
    # Provides methods for building different types of Mermaid diagrams with
    # syntax validation, error checking, and consistent formatting.
    #
    # @example
    #   builder = MermaidSyntaxBuilder.new
    #   content = builder.build_erd_diagram_from_dataset(dataset)
    #   # => "erDiagram\n    USERS ||--o{ ORDERS : user_id"
    class MermaidSyntaxBuilder
      include Dbwatcher::Logging

      # Custom error classes
      class SyntaxValidationError < StandardError; end
      class UnsupportedDiagramTypeError < StandardError; end

      # Supported Mermaid diagram types
      SUPPORTED_DIAGRAM_TYPES = %w[erDiagram classDiagram flowchart graph].freeze

      # Maximum content length to prevent memory issues
      MAX_CONTENT_LENGTH = 100_000

      # Initialize builder
      #
      # @param config [Hash] builder configuration (optional)
      # @option config [Logger] :logger logger instance
      def initialize(config = {})
        @config = config
        @logger = config[:logger] || Rails.logger
      end

      # Build ERD diagram from dataset
      #
      # @param dataset [DiagramData::Dataset] dataset to render
      # @param options [Hash] generation options
      # @return [String] Mermaid ERD syntax
      def build_erd_diagram_from_dataset(dataset, options = {})
        log_debug("Building ERD diagram from dataset with #{dataset.entities.size} entities and " \
                  "#{dataset.relationships.size} relationships")

        builder = MermaidSyntax::ErdBuilder.new(@config.merge(options))
        builder.build_from_dataset(dataset)
      end

      # Build class diagram from dataset
      #
      # @param dataset [DiagramData::Dataset] dataset to render
      # @param options [Hash] generation options
      # @return [String] Mermaid class diagram syntax
      def build_class_diagram_from_dataset(dataset, options = {})
        log_debug("Building class diagram from dataset with #{dataset.entities.size} entities and " \
                  "#{dataset.relationships.size} relationships")

        builder = MermaidSyntax::ClassDiagramBuilder.new(@config.merge(options))
        builder.build_from_dataset(dataset)
      end

      # Build flowchart diagram from dataset
      #
      # @param dataset [DiagramData::Dataset] dataset to render
      # @param options [Hash] generation options
      # @return [String] Mermaid flowchart syntax
      def build_flowchart_diagram_from_dataset(dataset, options = {})
        log_debug("Building flowchart diagram from dataset with #{dataset.entities.size} entities and " \
                  "#{dataset.relationships.size} relationships")

        builder = MermaidSyntax::FlowchartBuilder.new(@config.merge(options))
        builder.build_from_dataset(dataset)
      end

      # Build empty ERD diagram with message
      #
      # @param message [String] message to display
      # @return [String] Mermaid ERD syntax
      def build_empty_erd(message)
        builder = MermaidSyntax::ErdBuilder.new(@config)
        builder.build_empty(message)
      end

      # Build empty flowchart diagram with message
      #
      # @param message [String] message to display
      # @return [String] Mermaid flowchart syntax
      def build_empty_flowchart(message)
        builder = MermaidSyntax::FlowchartBuilder.new(@config)
        builder.build_empty(message)
      end

      # Build empty class diagram with message
      #
      # @param message [String] message to display
      # @return [String] Mermaid class diagram syntax
      def build_empty_class_diagram(message)
        builder = MermaidSyntax::ClassDiagramBuilder.new(@config)
        builder.build_empty(message)
      end

      # Build empty diagram of specified type
      #
      # @param message [String] message to display
      # @param diagram_type [String] type of diagram
      # @return [String] Mermaid syntax
      # @raise [UnsupportedDiagramTypeError] if type unsupported
      def build_empty_diagram(message, diagram_type)
        case diagram_type
        when "erDiagram", "erd"
          build_empty_erd(message)
        when "classDiagram", "class"
          build_empty_class_diagram(message)
        when "flowchart", "graph"
          build_empty_flowchart(message)
        else
          raise UnsupportedDiagramTypeError, "Unsupported diagram type: #{diagram_type}"
        end
      end

      # Build ERD diagram with isolated tables
      #
      # @param entities [Array<Entity>] isolated table entities
      # @param options [Hash] generation options
      # @return [String] Mermaid ERD syntax
      def build_erd_diagram_with_tables(entities, options = {})
        log_debug("Building ERD diagram with #{entities.size} isolated tables")

        dataset = Dbwatcher::Services::DiagramData::Dataset.new
        entities.each { |entity| dataset.add_entity(entity) }

        build_erd_diagram_from_dataset(dataset, options)
      end

      # Build flowchart diagram with isolated nodes
      #
      # @param entities [Array<Entity>] isolated node entities
      # @param options [Hash] generation options
      # @return [String] Mermaid flowchart syntax
      def build_flowchart_with_nodes(entities, options = {})
        log_debug("Building flowchart diagram with #{entities.size} isolated nodes")

        dataset = Dbwatcher::Services::DiagramData::Dataset.new
        entities.each { |entity| dataset.add_entity(entity) }

        build_flowchart_diagram_from_dataset(dataset, options)
      end

      # For backward compatibility with legacy code
      alias build_erd_diagram build_erd_diagram_from_dataset
      alias build_flowchart_diagram build_flowchart_diagram_from_dataset
    end
  end
end
