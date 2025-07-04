# frozen_string_literal: true

require "unit/services/diagram_helper"

RSpec.describe Dbwatcher::Services::MermaidSyntax::ClassDiagramBuilder do
  let(:entity_class) { Dbwatcher::Services::DiagramData::Entity }
  let(:attribute_class) { Dbwatcher::Services::DiagramData::Attribute }
  let(:relationship_class) { Dbwatcher::Services::DiagramData::Relationship }
  let(:dataset_class) { Dbwatcher::Services::DiagramData::Dataset }

  # Create a simple test entity
  let(:user_entity) do
    entity = entity_class.new(id: "user", name: "User", type: "model")
    entity.attributes << attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true })
    entity.attributes << attribute_class.new(name: "name", type: "string")
    entity
  end

  # Create an entity with methods
  let(:user_entity_with_methods) do
    entity = entity_class.new(id: "user", name: "User", type: "model")
    entity.attributes << attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true })
    entity.metadata[:methods] = [
      { name: "full_name()", type: "instance" }
    ]
    entity
  end

  # Create a simple dataset
  let(:simple_dataset) do
    dataset = dataset_class.new
    dataset.add_entity(user_entity)
    dataset
  end

  # Create a dataset with methods
  let(:dataset_with_methods) do
    dataset = dataset_class.new
    dataset.add_entity(user_entity_with_methods)
    dataset
  end

  describe "#build_from_dataset" do
    context "with default configuration" do
      let(:builder) { described_class.new }

      it "generates a class diagram with attributes and statistics" do
        result = builder.build_from_dataset(simple_dataset)

        # Basic structure
        expect(result).to include("classDiagram")
        expect(result).to include("direction LR")
        expect(result).to include("class User {")

        # Attributes section
        expect(result).to include("%% Attributes")
        expect(result).to include("+integer id")
        expect(result).to include("+string name")

        # Statistics section
        expect(result).to include("%% Statistics")
        expect(result).to include("+Stats: 2 attributes")
      end
    end

    context "with attributes disabled" do
      let(:builder) { described_class.new(show_attributes: false) }

      it "does not include attributes but still shows statistics" do
        result = builder.build_from_dataset(simple_dataset)

        expect(result).to include("class User {")
        expect(result).not_to include("%% Attributes")
        expect(result).not_to include("+integer id")
        expect(result).to include("%% Statistics")
        expect(result).to include("+Stats: 2 attributes")
      end
    end

    context "with methods enabled" do
      let(:builder) { described_class.new(show_methods: true) }

      it "includes methods with proper section dividers" do
        result = builder.build_from_dataset(dataset_with_methods)

        # Methods section
        expect(result).to include("%% Methods")
        expect(result).to include("+full_name()")

        # Dividers and statistics
        expect(result).to include("%% ----------------------")
        expect(result).to include("%% Statistics")
        expect(result).to include("+Stats: 1 methods")

        # Check that statistics appears after methods
        methods_index = result.index("%% Methods")
        statistics_index = result.index("%% Statistics")
        expect(methods_index).to be < statistics_index
      end
    end

    context "with empty dataset" do
      let(:empty_dataset) { dataset_class.new }
      let(:builder) { described_class.new }

      it "generates minimal class diagram" do
        result = builder.build_from_dataset(empty_dataset)
        expect(result).to eq("classDiagram\n    direction LR")
      end
    end
  end

  describe "#build_empty" do
    let(:builder) { described_class.new }

    it "generates an empty diagram with a message" do
      result = builder.build_empty("No data available")

      expect(result).to include("classDiagram")
      expect(result).to include("class EmptyState {")
      expect(result).to include("note for EmptyState \"No data available\"")
    end
  end
end
