# frozen_string_literal: true

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
      #   # => "classDiagram\n    class User {\n        +string name\n        +orders()\n    }\n    User --> Order : orders"
      class ClassDiagramBuilder < BaseBuilder
        # Build class diagram content from dataset
        #
        # @param dataset [DiagramData::Dataset] dataset to render
        # @return [String] Mermaid class diagram content
        def build_from_dataset(dataset)
          lines = ["classDiagram"]

          # Set diagram direction if specified
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

        # Build class definition
        #
        # @param entity [DiagramData::Entity] entity to render
        # @return [Array<String>] class definition lines
        def build_class_definition(entity)
          class_name = Sanitizer.class_name(entity.name)
          lines = ["    class #{class_name} {"]

          # Add attribute count as a statistical summary
          lines << "        +Stats: #{entity.attributes.size} attributes" if entity.attributes.any?

          # Add attributes section if enabled and available
          if show_attributes? && entity.attributes.any?
            lines << "        %% Attributes"
            entity.attributes.first(max_attributes).each do |attr|
              visibility = attr.metadata[:visibility] || "+"
              type = attr.type.to_s.empty? ? "any" : attr.type
              lines << "        #{visibility}#{type} #{attr.name}"
            end

            # Show message if there are more attributes than we're displaying
            if entity.attributes.size > max_attributes
              lines << "        %% ... #{entity.attributes.size - max_attributes} more attributes"
            end
          end

          # Add method count as a statistical summary
          lines << "        +Methods: #{entity.metadata[:methods].size} methods" if entity.metadata[:methods]&.any?

          # Add methods section if enabled and available
          if show_methods? && entity.metadata[:methods]&.any?
            lines << "        %% Methods"
            entity.metadata[:methods].first(max_methods).each do |method|
              visibility = method[:visibility] || "+"
              method_name = Sanitizer.method_name(method[:name])
              lines << "        #{visibility}#{method_name}"
            end

            # Show message if there are more methods than we're displaying
            if entity.metadata[:methods].size > max_methods
              lines << "        %% ... #{entity.metadata[:methods].size - max_methods} more methods"
            end
          end

          lines << "    }"
          lines << ""
          lines
        end

        # Build class relationship
        #
        # @param relationship [DiagramData::Relationship] relationship to render
        # @param dataset [DiagramData::Dataset] full dataset for context
        # @return [String] relationship definition line
        def build_class_relationship(relationship, dataset)
          source = Sanitizer.class_name(
            dataset.get_entity(relationship.source_id)&.name || relationship.source_id
          )

          target = Sanitizer.class_name(
            dataset.get_entity(relationship.target_id)&.name || relationship.target_id
          )

          label = Sanitizer.label(relationship.label)

          # Add cardinality if enabled
          if show_cardinality? && relationship.cardinality
            cardinality = CardinalityMapper.to_class(relationship.cardinality, cardinality_format)

            # Add relationship with label and cardinality
            if label && !label.empty?
              "    #{source} \"#{cardinality}\" --> #{target} : #{label}"
            else
              "    #{source} \"#{cardinality}\" --> #{target}"
            end
          elsif label && !label.empty?
            # Add relationship with label if available (without cardinality)
            "    #{source} --> #{target} : #{label}"
          else
            "    #{source} --> #{target}"
          end
        end
      end
    end
  end
end
