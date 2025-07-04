# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramData
      # Parameter object for relationship creation
      #
      # This class encapsulates parameters used for creating relationships
      # to avoid long parameter lists.
      class RelationshipParams
        attr_accessor :source_id, :target_id, :type, :label, :cardinality, :metadata

        # Initialize relationship parameters
        #
        # @param params [Hash] hash containing all parameters
        # @option params [String] :source_id ID of the source entity
        # @option params [String] :target_id ID of the target entity
        # @option params [String] :type relationship type
        # @option params [String] :label optional display label
        # @option params [String] :cardinality optional cardinality type
        # @option params [Hash] :metadata additional information
        def initialize(params = {})
          @source_id = params[:source_id]
          @target_id = params[:target_id]
          @type = params[:type]
          @label = params[:label]
          @cardinality = params[:cardinality]
          @metadata = params[:metadata] || {}
        end

        # Create from individual parameters
        #
        # @param params [Hash] parameters hash
        # @return [RelationshipParams] new instance
        def self.create(params)
          new(params)
        end

        # Convert to hash
        #
        # @return [Hash] hash representation of parameters
        def to_h
          {
            source_id: source_id,
            target_id: target_id,
            type: type,
            label: label,
            cardinality: cardinality,
            metadata: metadata
          }
        end
      end
    end
  end
end
