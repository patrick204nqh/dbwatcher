# frozen_string_literal: true

module Dbwatcher
  module Services
    module MermaidSyntax
      # Builder for Flowchart Diagrams in Mermaid syntax
      #
      # Generates Mermaid flowchart syntax from a standardized dataset with
      # support for nodes with attributes and edges with labels.
      #
      # @example
      #   builder = FlowchartBuilder.new(show_attributes: true)
      #   content = builder.build_from_dataset(dataset)
      #   # => "flowchart LR\n    User[User<br/>name, email]\n    User -->|has_many| Comment"
      class FlowchartBuilder < BaseBuilder
        # Build flowchart content from dataset
        #
        # @param dataset [DiagramData::Dataset] dataset to render
        # @return [String] Mermaid flowchart content
        def build_from_dataset(dataset)
          lines = ["flowchart #{diagram_direction}"]

          # Add node definitions
          dataset.entities.each_value do |entity|
            lines << build_flowchart_node(entity)
          end

          # Add relationships
          unless dataset.relationships.empty?
            lines << ""
            dataset.relationships.each do |relationship|
              lines << build_flowchart_relationship(relationship, dataset)
            end
          end

          lines.join("\n")
        end

        # Build empty flowchart with message
        #
        # @param message [String] message to display
        # @return [String] Mermaid flowchart content
        def build_empty(message)
          sanitized_message = sanitize_text(message)
          [
            "flowchart #{diagram_direction}",
            "    EmptyState[\"#{sanitized_message}\"]"
          ].join("\n")
        end

        private

        # Build flowchart node
        #
        # @param entity [DiagramData::Entity] entity to render
        # @return [String] node definition line
        def build_flowchart_node(entity)
          node_id = Sanitizer.node_id(entity.name)
          node_content = entity.name

          "    #{node_id}[\"#{node_content}\"]"
        end

        # Format entity name for node ID
        #
        # @param entity_id [String] entity ID
        # @param dataset [DiagramData::Dataset] dataset for entity lookup
        # @return [String] formatted node ID
        def format_node_id(entity_id, dataset)
          entity_name = dataset.get_entity(entity_id)&.name || entity_id
          Sanitizer.node_id(entity_name)
        end

        # Format relationship label with optional cardinality
        #
        # @param relationship [DiagramData::Relationship] relationship
        # @return [String] formatted label
        def format_relationship_label(relationship)
          label = Sanitizer.label(relationship.label)

          # Add cardinality to label if enabled
          if show_cardinality? && relationship.cardinality
            cardinality = CardinalityMapper.to_simple(relationship.cardinality, cardinality_format)
            label = label.empty? ? cardinality : "#{label} (#{cardinality})"
          end

          label
        end

        # Build flowchart relationship
        #
        # @param relationship [DiagramData::Relationship] relationship to render
        # @param dataset [DiagramData::Dataset] full dataset for context
        # @return [String] relationship definition line
        def build_flowchart_relationship(relationship, dataset)
          source = format_node_id(relationship.source_id, dataset)
          target = format_node_id(relationship.target_id, dataset)
          label = format_relationship_label(relationship)

          if label && !label.empty?
            "    #{source} -->|\"#{label}\"| #{target}"
          else
            "    #{source} --> #{target}"
          end
        end
      end
    end
  end
end
