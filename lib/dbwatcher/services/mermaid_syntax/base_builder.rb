# frozen_string_literal: true

module Dbwatcher
  module Services
    module MermaidSyntax
      # Base class for Mermaid syntax builders
      #
      # Provides common functionality and configuration options for all Mermaid
      # diagram builders. Subclasses should implement the build_from_dataset method.
      #
      # @example
      #   class MyDiagramBuilder < BaseBuilder
      #     def build_from_dataset(dataset)
      #       # Implementation
      #     end
      #   end
      class BaseBuilder
        include Dbwatcher::Logging

        # Initialize a new builder with configuration
        #
        # @param config [Hash] configuration options
        def initialize(config = {})
          @config = default_config.merge(config)
        end

        # Build diagram content from dataset
        #
        # @param dataset [DiagramData::Dataset] dataset to render
        # @return [String] Mermaid diagram content
        def build_from_dataset(dataset)
          raise NotImplementedError, "Subclasses must implement build_from_dataset"
        end

        # Build empty diagram with message
        #
        # @param message [String] message to display
        # @return [String] Mermaid diagram content
        def build_empty(message)
          raise NotImplementedError, "Subclasses must implement build_empty"
        end

        protected

        # Check if attributes should be shown
        #
        # @return [Boolean] true if attributes should be shown
        def show_attributes?
          @config[:show_attributes] == true
        end

        # Check if methods should be shown
        #
        # @return [Boolean] true if methods should be shown
        def show_methods?
          @config[:show_methods] == true
        end

        # Check if cardinality should be shown
        #
        # @return [Boolean] true if cardinality should be shown
        def show_cardinality?
          @config[:show_cardinality] != false
        end

        # Get maximum number of attributes to show
        #
        # @return [Integer] maximum number of attributes
        def max_attributes
          @config[:max_attributes] || 10
        end

        # Get maximum number of methods to show
        #
        # @return [Integer] maximum number of methods
        def max_methods
          @config[:max_methods] || 5
        end

        # Get diagram direction
        #
        # @return [String] diagram direction (TD, LR, etc.)
        def diagram_direction
          @config[:direction] || "LR"
        end

        # Check if table case should be preserved
        #
        # @return [Boolean] true if table case should be preserved
        def preserve_table_case?
          @config[:preserve_table_case] != false
        end

        # Get cardinality format
        #
        # @return [Symbol] cardinality format (:standard or :simple)
        def cardinality_format
          @config[:cardinality_format] || :simple
        end

        # Sanitize text for Mermaid
        #
        # @param text [String] text to sanitize
        # @return [String] sanitized text
        def sanitize_text(text)
          return "" unless text

          text.to_s.gsub(/["\n\r]/, " ").strip
        end

        # Default configuration options
        #
        # @return [Hash] default configuration
        def default_config
          {
            show_attributes: true,
            show_methods: false,
            show_cardinality: true,
            max_attributes: 10,
            max_methods: 5,
            direction: "LR",
            preserve_table_case: true,
            cardinality_format: :simple
          }
        end
      end
    end
  end
end
