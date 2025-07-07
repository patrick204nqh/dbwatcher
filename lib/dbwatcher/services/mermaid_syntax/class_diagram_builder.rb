# frozen_string_literal: true

require_relative "class_diagram_helper"

module Dbwatcher
  module Services
    module MermaidSyntax
      # Builder for Class Diagrams in Mermaid syntax
      #
      # Generates Mermaid class diagram syntax from a standardized dataset with
      # support for attributes, methods, and relationships with labels.
      #
      # @example
      #   builder = ClassDiagramBuilder.new(show_methods: true)
      #   content = builder.build_from_dataset(dataset)
      #   # => "classDiagram
      #   #     class User {
      #   #         +string name
      #   #         +orders()
      #   #     }
      #   #     User --> Order : orders"
      class ClassDiagramBuilder < BaseBuilder
        include ClassDiagramHelper

        # Build class diagram content from dataset
        #
        # @param dataset [DiagramData::Dataset] dataset to render
        # @return [String] Mermaid class diagram content
        def build_from_dataset(dataset)
          lines = ["classDiagram"]
          lines << "    direction #{diagram_direction}"

          # Add class definitions with attributes and methods
          dataset.entities.each_value do |entity|
            lines += build_class_definition(entity)
          end

          # Add relationships
          unless dataset.relationships.empty?
            lines << ""
            lines << "    %% Relationships"
            dataset.relationships.each do |relationship|
              lines << build_class_relationship(relationship, dataset)
            end
          end

          lines.join("\n")
        end

        # Build empty class diagram with message
        #
        # @param message [String] message to display
        # @return [String] Mermaid class diagram content
        def build_empty(message)
          sanitized_message = sanitize_text(message)
          [
            "classDiagram",
            "    direction #{diagram_direction}",
            "    class EmptyState {",
            "        +string message",
            "    }",
            "    note for EmptyState \"#{sanitized_message}\""
          ].join("\n")
        end

        private

        # Build attributes section for class definition
        def build_attributes_section(entity)
          return [] unless show_attributes? && entity.attributes.any?

          lines = ["        %% Attributes"]
          entity.attributes.first(max_attributes).each do |attr|
            lines << format_attribute_line(attr)
          end
          add_attributes_overflow_message(lines, entity)
          add_section_divider(lines, entity)
          lines
        end

        # Build methods section for class definition
        def build_methods_section(entity)
          return [] unless show_methods? && entity.metadata[:methods]&.any?

          lines = ["        %% Methods"]
          entity.metadata[:methods].first(max_methods).each do |method|
            lines << format_method_line(method)
          end
          if entity.metadata[:methods].size > max_methods
            lines << "        %% ... #{entity.metadata[:methods].size - max_methods} more methods"
          end
          lines << "        %% ----------------------"
          lines
        end

        # Build statistics section for class definition
        def build_statistics_section(entity)
          return [] unless entity.attributes.any? || entity.metadata[:methods]&.any?

          lines = ["        %% Statistics"]
          lines << "        +Stats: #{entity.attributes.size} attributes" if entity.attributes.any?
          lines << "        +Stats: #{entity.metadata[:methods].size} methods" if entity.metadata[:methods]&.any?
          lines
        end

        # Build class definition
        def build_class_definition(entity)
          display_name = Sanitizer.display_name(entity.name)

          # Use display name (with ::) for class definition instead of sanitized version
          lines = ["    class `#{display_name}` {"]
          lines += build_attributes_section(entity)
          lines += build_methods_section(entity)
          lines += build_statistics_section(entity)
          lines << "    }"
          lines << ""
          lines
        end

        # Build class relationship
        def build_class_relationship(relationship, dataset)
          source = format_class_name(relationship.source_id, dataset)
          target = format_class_name(relationship.target_id, dataset)
          label = Sanitizer.label(relationship.label)

          relationship_line = "    #{source}"
          if show_cardinality? && relationship.cardinality
            cardinality = CardinalityMapper.to_class(relationship.cardinality, cardinality_format)
            relationship_line += " \"#{cardinality}\""
          end
          relationship_line += " --> #{target}"
          relationship_line += " : #{label}" if label && !label.empty?
          relationship_line
        end
      end
    end
  end
end
