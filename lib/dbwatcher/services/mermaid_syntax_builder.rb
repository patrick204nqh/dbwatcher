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
    #   content = builder.build_erd_diagram(relationships)
    #   # => "erDiagram\n    USERS ||--o{ ORDERS : user_id"
    class MermaidSyntaxBuilder
      # Custom error classes
      class SyntaxValidationError < StandardError; end
      class UnsupportedDiagramTypeError < StandardError; end

      # Supported Mermaid diagram types
      SUPPORTED_DIAGRAM_TYPES = %w[erDiagram flowchart graph].freeze

      # Maximum content length to prevent memory issues
      MAX_CONTENT_LENGTH = 100_000

      # Initialize builder with configuration
      #
      # @param config [Hash] builder configuration
      # @option config [Boolean] :validate_syntax enable syntax validation
      # @option config [Boolean] :sanitize_content sanitize input content
      # @option config [Boolean] :apply_styling apply default styling
      # @option config [Integer] :max_nodes maximum number of nodes
      # @option config [Integer] :max_edges maximum number of edges
      # @option config [Logger] :logger logger instance
      def initialize(config = {})
        @config = default_config.merge(config)
        @logger = @config[:logger] || Rails.logger
      end

      # Build ERD diagram from relationships
      #
      # @param relationships [Array<Hash>] database relationships
      # @param options [Hash] generation options
      # @return [String] Mermaid ERD syntax
      # @raise [ArgumentError] if relationships invalid
      # @raise [SyntaxValidationError] if generated syntax invalid
      def build_erd_diagram(relationships, options = {})
        @logger.debug "Building ERD diagram with #{relationships.size} relationships"

        validate_relationships!(relationships)
        config = @config.merge(options)

        content = ["erDiagram"]
        content += build_table_definitions(relationships, config)
        content += build_relationship_definitions(relationships, config)

        result = content.join("\n")
        validate_syntax!(result, "erDiagram")
        result
      end

      # Build flowchart diagram from associations
      #
      # @param associations [Array<Hash>] model associations
      # @param options [Hash] generation options
      # @return [String] Mermaid flowchart syntax
      # @raise [ArgumentError] if associations invalid
      # @raise [SyntaxValidationError] if generated syntax invalid
      def build_flowchart_diagram(associations, options = {})
        @logger.debug "Building flowchart diagram with #{associations.size} associations"

        validate_associations!(associations)
        config = @config.merge(options)

        direction = config[:layout_direction] || "TD"
        content = ["flowchart #{direction}"]
        content += build_node_definitions(associations, config)
        content += build_edge_definitions(associations, config)
        content += build_styling_definitions(config) if config[:apply_styling]

        result = content.join("\n")
        validate_syntax!(result, "flowchart")
        result
      end

      # Build empty ERD diagram with message
      #
      # @param message [String] message to display
      # @return [String] Mermaid ERD syntax
      def build_empty_erd(message)
        sanitized_message = sanitize_text(message)
        content = [
          "erDiagram",
          "    EmptyState {",
          "        string message \"#{sanitized_message}\"",
          "    }"
        ]
        content.join("\n")
      end

      # Build empty flowchart diagram with message
      #
      # @param message [String] message to display
      # @return [String] Mermaid flowchart syntax
      def build_empty_flowchart(message)
        sanitized_message = sanitize_text(message)
        content = [
          "flowchart TD",
          "    Empty[\"#{sanitized_message}\"]",
          "    style Empty fill:#f9f9f9,stroke:#ccc,stroke-width:2px"
        ]
        content.join("\n")
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
        when "flowchart", "graph"
          build_empty_flowchart(message)
        else
          raise UnsupportedDiagramTypeError, "Unsupported diagram type: #{diagram_type}"
        end
      end

      private

      # Default configuration
      #
      # @return [Hash] default configuration
      def default_config
        {
          max_nodes: 100,
          max_edges: 200,
          apply_styling: true,
          sanitize_content: true,
          validate_syntax: true,
          layout_direction: "TD"
        }
      end

      # Validate relationships array
      #
      # @param relationships [Array] relationships to validate
      # @raise [ArgumentError] if validation fails
      def validate_relationships!(relationships)
        raise ArgumentError, "Relationships cannot be nil" if relationships.nil?
        raise ArgumentError, "Relationships must be an array" unless relationships.is_a?(Array)

        return unless relationships.size > @config[:max_edges]

        raise ArgumentError, "Too many relationships (max: #{@config[:max_edges]})"
      end

      # Validate associations array
      #
      # @param associations [Array] associations to validate
      # @raise [ArgumentError] if validation fails
      def validate_associations!(associations)
        raise ArgumentError, "Associations cannot be nil" if associations.nil?
        raise ArgumentError, "Associations must be an array" unless associations.is_a?(Array)

        return unless associations.size > @config[:max_edges]

        raise ArgumentError, "Too many associations (max: #{@config[:max_edges]})"
      end

      # Validate generated Mermaid syntax
      #
      # @param mermaid_content [String] generated content
      # @param expected_type [String] expected diagram type
      # @raise [SyntaxValidationError] if validation fails
      def validate_syntax!(mermaid_content, expected_type)
        return unless @config[:validate_syntax]

        raise SyntaxValidationError, "Generated Mermaid content is empty" if mermaid_content.blank?

        if mermaid_content.length > MAX_CONTENT_LENGTH
          raise SyntaxValidationError, "Generated content too large (#{mermaid_content.length} chars)"
        end

        unless mermaid_content.start_with?(expected_type)
          raise SyntaxValidationError, "Content doesn't start with expected diagram type: #{expected_type}"
        end

        validate_mermaid_syntax_rules(mermaid_content, expected_type)
      end

      # Validate Mermaid-specific syntax rules
      #
      # @param content [String] diagram content
      # @param diagram_type [String] diagram type
      def validate_mermaid_syntax_rules(content, diagram_type)
        lines = content.split("\n")
        case diagram_type
        when "erDiagram"
          validate_erd_syntax_rules(lines)
        when "flowchart"
          validate_flowchart_syntax_rules(lines)
        end
      end

      # Validate ERD syntax rules
      #
      # @param lines [Array<String>] content lines
      def validate_erd_syntax_rules(lines)
        lines.each_with_index do |line, index|
          next if line.strip.empty? || line.strip == "erDiagram"

          # Check for valid ERD patterns
          if line.match?(/\s+\w+\s+\|\w+\|\s*\w+\s*:\s*\w+/) ||
             line.match?(/\s+\w+\s*\{/) ||
             line.match?(/\s+\}/) ||
             line.match?(/\s+\w+\s+\w+/) ||
             line.match?(/\s+%%/)
            # Valid ERD syntax
          else
            @logger.warn "Potentially invalid ERD syntax at line #{index + 1}: #{line}"
          end
        end
      end

      # Validate flowchart syntax rules
      #
      # @param lines [Array<String>] content lines
      def validate_flowchart_syntax_rules(lines)
        lines.each_with_index do |line, index|
          next if line.strip.empty? || line.match?(/^flowchart\s+(TD|LR|RL|BT)$/)

          # Check for valid flowchart patterns
          if line.match?(/\s+\w+\[.*\]/) ||
             line.match?(/\s+\w+\s*-->.*\w+/) ||
             line.match?(/\s+style\s+\w+/) ||
             line.match?(/\s+%%/)
            # Valid flowchart syntax
          else
            @logger.warn "Potentially invalid flowchart syntax at line #{index + 1}: #{line}"
          end
        end
      end

      # Sanitize text for Mermaid output
      #
      # @param text [String] text to sanitize
      # @return [String] sanitized text
      def sanitize_text(text)
        return "" if text.blank?
        return text unless @config[:sanitize_content]

        # Remove or escape characters that could break Mermaid syntax
        text.gsub(/["\\]/, "").gsub("\n", " ").strip
      end

      # Build table definitions for ERD
      #
      # @param relationships [Array<Hash>] database relationships
      # @param config [Hash] generation configuration
      # @return [Array<String>] table definition lines
      def build_table_definitions(relationships, config)
        tables = extract_unique_tables(relationships)
        lines = []

        tables.each do |table|
          safe_name = sanitize_table_name(table)
          lines << "    #{safe_name} {"

          lines << "        string id PK" if config[:show_columns]

          lines << "    }"
        end

        lines
      end

      # Build relationship definitions for ERD
      #
      # @param relationships [Array<Hash>] database relationships
      # @param config [Hash] generation configuration
      # @return [Array<String>] relationship definition lines
      def build_relationship_definitions(relationships, config)
        lines = []

        relationships.each do |rel|
          next unless valid_relationship?(rel)

          from_table = sanitize_table_name(rel[:from_table])
          to_table = sanitize_table_name(rel[:to_table])
          cardinality = infer_erd_cardinality(rel)
          constraint = rel[:constraint_name] || rel[:from_column] || "fk"

          lines << "    #{to_table} #{cardinality} #{from_table} : \"#{constraint}\""
        end

        lines
      end

      # Build node definitions for flowchart
      #
      # @param associations [Array<Hash>] model associations
      # @param config [Hash] generation configuration
      # @return [Array<String>] node definition lines
      def build_node_definitions(associations, config)
        lines = []
        added_nodes = Set.new

        associations.each do |assoc|
          next unless valid_association?(assoc)

          # Add source node
          source_id = generate_node_id(assoc[:source_model])
          unless added_nodes.include?(source_id)
            lines << "    #{source_id}[\"#{assoc[:source_model]}\"]"
            added_nodes << source_id
          end

          # Add target node if present
          next unless assoc[:target_model] && assoc[:type] != "node_only"

          target_id = generate_node_id(assoc[:target_model])
          unless added_nodes.include?(target_id)
            lines << "    #{target_id}[\"#{assoc[:target_model]}\"]"
            added_nodes << target_id
          end
        end

        lines
      end

      # Build edge definitions for flowchart
      #
      # @param associations [Array<Hash>] model associations
      # @param config [Hash] generation configuration
      # @return [Array<String>] edge definition lines
      def build_edge_definitions(associations, config)
        lines = []

        associations.each do |assoc|
          next unless should_add_edge?(assoc)

          source_id = generate_node_id(assoc[:source_model])
          target_id = generate_node_id(assoc[:target_model])
          association_name = assoc[:association_name]

          lines << if association_name
                     "    #{source_id} -->|#{association_name}| #{target_id}"
                   else
                     "    #{source_id} --> #{target_id}"
                   end
        end

        lines
      end

      # Build styling definitions
      #
      # @param config [Hash] generation configuration
      # @return [Array<String>] styling definition lines
      def build_styling_definitions(config)
        [
          "    classDef default fill:lightblue,stroke:blue,stroke-width:1px"
        ]
      end

      # Extract unique table names from relationships
      #
      # @param relationships [Array<Hash>] database relationships
      # @return [Set<String>] unique table names
      def extract_unique_tables(relationships)
        tables = Set.new
        relationships.each do |rel|
          tables << rel[:from_table].to_s if rel[:from_table]
          tables << rel[:to_table].to_s if rel[:to_table]
        end
        tables
      end

      # Sanitize table name for Mermaid
      #
      # @param table_name [String] raw table name
      # @return [String] sanitized table name
      def sanitize_table_name(table_name)
        return "UNKNOWN_TABLE" unless table_name.is_a?(String) && !table_name.empty?

        table_name.strip.upcase.gsub(/[^A-Z0-9_]/, "_")
      end

      # Check if relationship is valid
      #
      # @param rel [Hash] relationship data
      # @return [Boolean] true if valid
      def valid_relationship?(rel)
        rel.is_a?(Hash) && rel[:from_table] && rel[:to_table]
      end

      # Check if association is valid
      #
      # @param assoc [Hash] association data
      # @return [Boolean] true if valid
      def valid_association?(assoc)
        assoc.is_a?(Hash) && !assoc[:source_model].to_s.empty?
      end

      # Check if edge should be added for association
      #
      # @param assoc [Hash] association data
      # @return [Boolean] true if edge should be added
      def should_add_edge?(assoc)
        valid_association?(assoc) &&
          assoc[:target_model] &&
          assoc[:type] != "node_only" &&
          !assoc[:target_model].to_s.empty?
      end

      # Generate consistent node ID from model name
      #
      # @param model_name [String] model name
      # @return [String] node ID
      def generate_node_id(model_name)
        "node_#{Digest::MD5.hexdigest(model_name.to_s)[0, 8]}"
      end

      # Infer ERD cardinality from relationship
      #
      # @param relationship [Hash] relationship data
      # @return [String] Mermaid cardinality notation
      def infer_erd_cardinality(relationship)
        # Default to one-to-many for foreign keys
        # Could be enhanced with more sophisticated detection
        "||--o{"
      end
    end
  end
end
