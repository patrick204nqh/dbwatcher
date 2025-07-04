# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::DiagramTypeRegistry do
  let(:registry) { described_class.new }

  describe "::DIAGRAM_TYPES" do
    it "includes database_tables type" do
      expect(described_class::DIAGRAM_TYPES).to have_key("database_tables")
      type = described_class::DIAGRAM_TYPES["database_tables"]
      expect(type[:strategy_class]).to eq("Dbwatcher::Services::DiagramStrategies::ErdDiagramStrategy")
      expect(type[:analyzer_class]).to eq("Dbwatcher::Services::DiagramAnalyzers::ForeignKeyAnalyzer")
      expect(type[:mermaid_type]).to eq("erDiagram")
    end

    it "includes database_tables_inferred type" do
      expect(described_class::DIAGRAM_TYPES).to have_key("database_tables_inferred")
      type = described_class::DIAGRAM_TYPES["database_tables_inferred"]
      expect(type[:strategy_class]).to eq("Dbwatcher::Services::DiagramStrategies::ErdDiagramStrategy")
      expect(type[:analyzer_class]).to eq("Dbwatcher::Services::DiagramAnalyzers::InferredRelationshipAnalyzer")
      expect(type[:mermaid_type]).to eq("erDiagram")
    end

    it "includes model_associations type" do
      expect(described_class::DIAGRAM_TYPES).to have_key("model_associations")
      type = described_class::DIAGRAM_TYPES["model_associations"]
      expect(type[:strategy_class]).to eq("Dbwatcher::Services::DiagramStrategies::ClassDiagramStrategy")
      expect(type[:analyzer_class]).to eq("Dbwatcher::Services::DiagramAnalyzers::ModelAssociationAnalyzer")
      expect(type[:mermaid_type]).to eq("classDiagram")
    end

    it "includes model_associations_flowchart type" do
      expect(described_class::DIAGRAM_TYPES).to have_key("model_associations_flowchart")
      type = described_class::DIAGRAM_TYPES["model_associations_flowchart"]
      expect(type[:strategy_class]).to eq("Dbwatcher::Services::DiagramStrategies::FlowchartDiagramStrategy")
      expect(type[:analyzer_class]).to eq("Dbwatcher::Services::DiagramAnalyzers::ModelAssociationAnalyzer")
      expect(type[:mermaid_type]).to eq("flowchart")
    end
  end

  describe "#available_types" do
    it "returns all diagram types" do
      types = registry.available_types

      expect(types).to include("database_tables")
      expect(types).to include("database_tables_inferred")
      expect(types).to include("model_associations")
      expect(types).to include("model_associations_flowchart")
    end
  end

  describe "#type_exists?" do
    it "returns true for known type" do
      expect(registry.type_exists?("model_associations")).to be true
    end

    it "returns false for unknown type" do
      expect(registry.type_exists?("unknown_type")).to be false
    end
  end

  describe "#type_metadata" do
    it "returns metadata for diagram type" do
      metadata = registry.type_metadata("model_associations")

      expect(metadata[:display_name]).to eq("Model Associations")
      expect(metadata[:mermaid_type]).to eq("classDiagram")
    end

    it "raises error for unknown type" do
      expect { registry.type_metadata("unknown_type") }.to raise_error(Dbwatcher::Services::DiagramTypeRegistry::UnknownTypeError)
    end
  end

  describe "#create_strategy" do
    it "creates strategy instance for diagram type" do
      allow(Dbwatcher::Services::DiagramStrategies::ClassDiagramStrategy).to receive(:new).and_return(double)

      registry.create_strategy("model_associations")

      expect(Dbwatcher::Services::DiagramStrategies::ClassDiagramStrategy).to have_received(:new)
    end

    it "raises error for unknown type" do
      expect { registry.create_strategy("unknown_type") }.to raise_error(Dbwatcher::Services::DiagramTypeRegistry::UnknownTypeError)
    end
  end

  describe "#create_analyzer" do
    it "creates analyzer instance for diagram type" do
      session = double("session")
      allow(Dbwatcher::Services::DiagramAnalyzers::ModelAssociationAnalyzer).to receive(:new).and_return(double)

      registry.create_analyzer("model_associations", session)

      expect(Dbwatcher::Services::DiagramAnalyzers::ModelAssociationAnalyzer).to have_received(:new).with(session)
    end

    it "raises error for unknown type" do
      expect { registry.create_analyzer("unknown_type", double) }.to raise_error(Dbwatcher::Services::DiagramTypeRegistry::UnknownTypeError)
    end
  end
end
