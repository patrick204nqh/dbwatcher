# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramData
      # Complete dataset for diagram generation
      #
      # This class serves as a container for all diagram data including entities
      # and relationships, with validation and management capabilities.
      #
      # @example
      #   dataset = DiagramDataset.new
      #   dataset.add_entity(BaseEntity.new(id: "users", name: "User", type: "table"))
      #   dataset.add_entity(BaseEntity.new(id: "orders", name: "Order", type: "table"))
      #   dataset.add_relationship(Relationship.new(
      #     source_id: "users", target_id: "orders", type: "has_many"
      #   ))
      #   dataset.valid? # => true
      #   dataset.to_h   # => complete dataset hash
      class DiagramDataset
        attr_reader :entities, :relationships, :metadata

        # Initialize empty dataset
        #
        # @param metadata [Hash] optional dataset-level metadata
        def initialize(metadata: {})
          @entities = {}
          @relationships = []
          @metadata = metadata.is_a?(Hash) ? metadata : {}
        end

        # Add entity to dataset
        #
        # @param entity [BaseEntity] entity to add
        # @return [BaseEntity] the added entity
        # @raise [ArgumentError] if entity is invalid
        def add_entity(entity)
          raise ArgumentError, "Entity must be a BaseEntity instance" unless entity.is_a?(BaseEntity)

          raise ArgumentError, "Entity is invalid: #{entity.validation_errors.join(", ")}" unless entity.valid?

          @entities[entity.id] = entity
          entity
        end

        # Add relationship to dataset
        #
        # @param relationship [Relationship] relationship to add
        # @return [Relationship] the added relationship
        # @raise [ArgumentError] if relationship is invalid
        def add_relationship(relationship)
          raise ArgumentError, "Relationship must be a Relationship instance" unless relationship.is_a?(Relationship)

          unless relationship.valid?
            raise ArgumentError, "Relationship is invalid: #{relationship.validation_errors.join(", ")}"
          end

          @relationships << relationship
          relationship
        end

        # Get entity by ID
        #
        # @param id [String] entity ID
        # @return [BaseEntity, nil] entity or nil if not found
        def get_entity(id)
          @entities[id.to_s]
        end

        # Check if entity exists
        #
        # @param id [String] entity ID
        # @return [Boolean] true if entity exists
        def has_entity?(id)
          @entities.key?(id.to_s)
        end

        # Remove entity by ID
        #
        # @param id [String] entity ID
        # @return [BaseEntity, nil] removed entity or nil if not found
        def remove_entity(id)
          entity = @entities.delete(id.to_s)

          # Remove relationships involving this entity
          if entity
            @relationships.reject! do |rel|
              rel.source_id == id.to_s || rel.target_id == id.to_s
            end
          end

          entity
        end

        # Remove relationship
        #
        # @param relationship [Relationship] relationship to remove
        # @return [Boolean] true if relationship was removed
        def remove_relationship(relationship)
          !@relationships.delete(relationship).nil?
        end

        # Get relationships for an entity
        #
        # @param entity_id [String] entity ID
        # @param direction [Symbol] :outgoing, :incoming, or :all
        # @return [Array<Relationship>] filtered relationships
        def relationships_for(entity_id, direction: :all)
          id = entity_id.to_s

          case direction
          when :outgoing
            @relationships.select { |rel| rel.source_id == id }
          when :incoming
            @relationships.select { |rel| rel.target_id == id }
          when :all
            @relationships.select { |rel| rel.source_id == id || rel.target_id == id }
          else
            raise ArgumentError, "Direction must be :outgoing, :incoming, or :all"
          end
        end

        # Check if dataset is valid
        #
        # @return [Boolean] true if dataset is valid
        def valid?
          validation_errors.empty?
        end

        # Get validation errors
        #
        # @return [Array<String>] array of validation error messages
        def validation_errors
          errors = []

          # Validate all entities
          @entities.each do |id, entity|
            errors << "Entity #{id} is invalid: #{entity.validation_errors.join(", ")}" unless entity.valid?
          end

          # Validate all relationships
          @relationships.each_with_index do |relationship, index|
            unless relationship.valid?
              errors << "Relationship #{index} is invalid: #{relationship.validation_errors.join(", ")}"
            end

            # Check that referenced entities exist
            unless has_entity?(relationship.source_id)
              errors << "Relationship #{index} references non-existent source entity: #{relationship.source_id}"
            end

            unless has_entity?(relationship.target_id)
              errors << "Relationship #{index} references non-existent target entity: #{relationship.target_id}"
            end
          end

          # Validate metadata
          errors << "Metadata must be a Hash" unless @metadata.is_a?(Hash)

          errors
        end

        # Get dataset statistics
        #
        # @return [Hash] statistics about the dataset
        def stats
          {
            entity_count: @entities.size,
            relationship_count: @relationships.size,
            entity_types: @entities.values.map(&:type).uniq.sort,
            relationship_types: @relationships.map(&:type).uniq.sort,
            isolated_entities: isolated_entities.map(&:id),
            connected_entities: connected_entities.map(&:id)
          }
        end

        # Get entities with no relationships
        #
        # @return [Array<BaseEntity>] isolated entities
        def isolated_entities
          connected_ids = (@relationships.map(&:source_id) + @relationships.map(&:target_id)).uniq
          @entities.values.reject { |entity| connected_ids.include?(entity.id) }
        end

        # Get entities with at least one relationship
        #
        # @return [Array<BaseEntity>] connected entities
        def connected_entities
          connected_ids = (@relationships.map(&:source_id) + @relationships.map(&:target_id)).uniq
          @entities.values.select { |entity| connected_ids.include?(entity.id) }
        end

        # Check if dataset is empty
        #
        # @return [Boolean] true if no entities or relationships
        def empty?
          @entities.empty? && @relationships.empty?
        end

        # Clear all data from dataset
        #
        # @return [self] for method chaining
        def clear
          @entities.clear
          @relationships.clear
          @metadata.clear
          self
        end

        # Serialize dataset to hash
        #
        # @return [Hash] serialized dataset
        def to_h
          {
            entities: @entities.transform_values(&:to_h),
            relationships: @relationships.map(&:to_h),
            metadata: @metadata,
            stats: stats
          }
        end

        # Serialize dataset to JSON
        #
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Create dataset from hash
        #
        # @param hash [Hash] dataset data
        # @return [DiagramDataset] new dataset instance
        def self.from_h(hash)
          dataset = new(metadata: hash[:metadata] || hash["metadata"] || {})

          # Load entities
          entities_data = hash[:entities] || hash["entities"] || {}
          entities_data.each do |_id, entity_data|
            entity = BaseEntity.from_h(entity_data)
            dataset.add_entity(entity)
          end

          # Load relationships
          relationships_data = hash[:relationships] || hash["relationships"] || []
          relationships_data.each do |relationship_data|
            relationship = Relationship.from_h(relationship_data)
            dataset.add_relationship(relationship)
          end

          dataset
        end

        # Create dataset from JSON
        #
        # @param json [String] JSON string
        # @return [DiagramDataset] new dataset instance
        def self.from_json(json)
          from_h(JSON.parse(json))
        end

        # String representation of dataset
        #
        # @return [String] string representation
        def to_s
          "#{self.class.name}(entities: #{@entities.size}, relationships: #{@relationships.size})"
        end

        # Detailed string representation
        #
        # @return [String] detailed string representation
        def inspect
          "#{self.class.name}(entities: #{@entities.size}, relationships: #{@relationships.size}, " \
            "metadata: #{@metadata.inspect})"
        end
      end
    end
  end
end
