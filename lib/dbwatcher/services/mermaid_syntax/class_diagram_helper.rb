# frozen_string_literal: true

module Dbwatcher
  module Services
    module MermaidSyntax
      # Helper module for ClassDiagramBuilder
      #
      # Contains formatting methods for class diagram elements
      module ClassDiagramHelper
        # Format an attribute for class diagram
        def format_attribute_line(attr)
          visibility = attr.metadata[:visibility] || "+"
          type = attr.type.to_s.empty? ? "any" : attr.type
          "        #{visibility}#{type} #{attr.name}"
        end

        # Add overflow message for attributes if needed
        def add_attributes_overflow_message(lines, entity)
          return unless entity.attributes.size > max_attributes

          lines << "        %% ... #{entity.attributes.size - max_attributes} more attributes"
        end

        # Add section divider if methods will follow
        def add_section_divider(lines, entity)
          return unless show_methods? && entity.metadata[:methods]&.any?

          lines << "        %% ----------------------"
        end

        # Format a method for class diagram
        def format_method_line(method)
          visibility = method[:visibility] || "+"
          method_name = Sanitizer.method_name(method[:name])
          "        #{visibility}#{method_name}"
        end

        # Format class name for diagram
        def format_class_name(entity_id, dataset)
          entity_name = dataset.get_entity(entity_id)&.name || entity_id
          Sanitizer.class_name(entity_name)
        end
      end
    end
  end
end
