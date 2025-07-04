# frozen_string_literal: true

require "unit/services/diagram_helper"

RSpec.describe Dbwatcher::Services::MermaidSyntax::FlowchartBuilder do
  let(:entity_class) { Dbwatcher::Services::DiagramData::Entity }
  let(:attribute_class) { Dbwatcher::Services::DiagramData::Attribute }
  let(:relationship_class) { Dbwatcher::Services::DiagramData::Relationship }
  let(:dataset_class) { Dbwatcher::Services::DiagramData::Dataset }

  # Create simple test entities
  let(:user_entity) do
    entity_class.new(id: "user", name: "User", type: "model")
  end

  let(:post_entity) do
    entity_class.new(id: "post", name: "Post", type: "model")
  end

  # Create relationships
  let(:user_post_relationship) do
    relationship_class.new(
      source_id: "user",
      target_id: "post",
      type: "has_many",
      label: "posts",
      cardinality: "one_to_many"
    )
  end

  # Create a simple dataset
  let(:simple_dataset) do
    dataset = dataset_class.new
    dataset.add_entity(user_entity)
    dataset.add_entity(post_entity)
    dataset.add_relationship(user_post_relationship)
    dataset
  end

  describe "#build_from_dataset" do
    context "with default configuration" do
      let(:builder) { described_class.new }

      it "generates a flowchart with nodes and relationships" do
        result = builder.build_from_dataset(simple_dataset)

        # Basic structure
        expect(result).to include("flowchart LR")
        expect(result).to include('User["User"]')
        expect(result).to include('Post["Post"]')

        # Relationship with cardinality
        expect(result).to include('User -->|"posts (1:N)"| Post')
      end
    end

    context "with cardinality options" do
      it "shows cardinality when enabled" do
        builder = described_class.new(show_cardinality: true)
        result = builder.build_from_dataset(simple_dataset)
        expect(result).to include('User -->|"posts (1:N)"| Post')
      end

      it "does not show cardinality when disabled" do
        builder = described_class.new(show_cardinality: false)
        result = builder.build_from_dataset(simple_dataset)
        expect(result).to include('User -->|"posts"| Post')
      end
    end

    context "with direction option" do
      it "uses the specified direction" do
        builder = described_class.new(direction: "TD")
        result = builder.build_from_dataset(simple_dataset)
        expect(result).to include("flowchart TD")
      end
    end

    context "with empty dataset" do
      let(:empty_dataset) { dataset_class.new }
      let(:builder) { described_class.new }

      it "generates minimal flowchart" do
        result = builder.build_from_dataset(empty_dataset)
        expect(result).to eq("flowchart LR")
      end
    end
  end

  describe "#build_empty" do
    let(:builder) { described_class.new }

    it "generates empty flowchart with message" do
      result = builder.build_empty("No data available")

      expect(result).to include("flowchart LR")
      expect(result).to include('EmptyState["No data available"]')
    end
  end
end
