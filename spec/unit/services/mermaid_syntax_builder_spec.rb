# frozen_string_literal: true

require "unit/services/diagram_helper"

RSpec.describe Dbwatcher::Services::MermaidSyntaxBuilder do
  let(:entity_class) { Dbwatcher::Services::DiagramData::Entity }
  let(:attribute_class) { Dbwatcher::Services::DiagramData::Attribute }
  let(:relationship_class) { Dbwatcher::Services::DiagramData::Relationship }
  let(:dataset_class) { Dbwatcher::Services::DiagramData::Dataset }

  let(:user_entity) do
    entity = entity_class.new(id: "user", name: "User", type: "model")
    entity.attributes << attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true })
    entity.attributes << attribute_class.new(name: "name", type: "string")
    entity
  end

  let(:post_entity) do
    entity = entity_class.new(id: "post", name: "Post", type: "model")
    entity.attributes << attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true })
    entity.attributes << attribute_class.new(name: "title", type: "string")
    entity
  end

  let(:relationship) do
    relationship_class.new(
      source_id: "user",
      target_id: "post",
      type: "has_many",
      label: "posts",
      cardinality: "one_to_many"
    )
  end

  let(:dataset) do
    dataset = dataset_class.new
    dataset.add_entity(user_entity)
    dataset.add_entity(post_entity)
    dataset.add_relationship(relationship)
    dataset
  end

  let(:config) do
    {
      show_attributes: true,
      show_methods: true,
      show_cardinality: true,
      max_attributes_per_entity: 5,
      preserve_table_case: true
    }
  end

  let(:builder) { described_class.new(config) }

  describe "#build_class_diagram_from_dataset" do
    it "delegates to ClassDiagramBuilder" do
      expect_any_instance_of(Dbwatcher::Services::MermaidSyntax::ClassDiagramBuilder)
        .to receive(:build_from_dataset).with(dataset).and_return("class diagram content")

      result = builder.build_class_diagram_from_dataset(dataset)
      expect(result).to eq("class diagram content")
    end

    it "passes configuration to ClassDiagramBuilder" do
      expect(Dbwatcher::Services::MermaidSyntax::ClassDiagramBuilder)
        .to receive(:new).with(config).and_call_original

      builder.build_class_diagram_from_dataset(dataset)
    end
  end

  describe "#build_flowchart_diagram_from_dataset" do
    it "delegates to FlowchartBuilder" do
      expect_any_instance_of(Dbwatcher::Services::MermaidSyntax::FlowchartBuilder)
        .to receive(:build_from_dataset).with(dataset).and_return("flowchart content")

      result = builder.build_flowchart_diagram_from_dataset(dataset)
      expect(result).to eq("flowchart content")
    end

    it "passes configuration to FlowchartBuilder" do
      expect(Dbwatcher::Services::MermaidSyntax::FlowchartBuilder)
        .to receive(:new).with(config).and_call_original

      builder.build_flowchart_diagram_from_dataset(dataset)
    end
  end

  describe "#build_erd_diagram_from_dataset" do
    it "delegates to ErdBuilder" do
      expect_any_instance_of(Dbwatcher::Services::MermaidSyntax::ErdBuilder)
        .to receive(:build_from_dataset).with(dataset).and_return("erd diagram content")

      result = builder.build_erd_diagram_from_dataset(dataset)
      expect(result).to eq("erd diagram content")
    end

    it "passes configuration to ErdBuilder" do
      expect(Dbwatcher::Services::MermaidSyntax::ErdBuilder)
        .to receive(:new).with(config).and_call_original

      builder.build_erd_diagram_from_dataset(dataset)
    end
  end

  describe "#build_empty_erd" do
    it "generates empty ERD diagram with message" do
      expect_any_instance_of(Dbwatcher::Services::MermaidSyntax::ErdBuilder)
        .to receive(:build_empty).with("No data available").and_call_original

      result = builder.build_empty_erd("No data available")

      expect(result).to include("erDiagram")
      expect(result).to include("EMPTY_STATE {")
      expect(result).to include('string message "No data available"')
      expect(result).not_to include("direction")
    end
  end

  describe "#build_empty_flowchart" do
    it "generates empty flowchart with message" do
      result = builder.build_empty_flowchart("No data available")

      expect(result).to include("flowchart LR")
      expect(result).to include("No data available")
    end
  end
end
