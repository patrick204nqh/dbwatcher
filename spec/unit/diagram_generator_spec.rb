# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Services::DiagramGenerator do
  let(:session_id) { "test-session-123" }
  let(:mock_session) { double("Session", id: session_id) }
  let(:mock_registry) { instance_double("Dbwatcher::Services::DiagramTypeRegistry") }
  let(:mock_error_handler) { instance_double("Dbwatcher::Services::DiagramErrorHandler") }
  let(:mock_logger) { instance_double("Logger", info: nil, debug: nil, warn: nil) }
  let(:mock_analyzer) { double("Analyzer") }
  let(:mock_strategy) { double("Strategy") }
  let(:mock_dataset) { double("Dataset", entities: [], relationships: []) }

  let(:dependencies) do
    {
      registry: mock_registry,
      error_handler: mock_error_handler,
      logger: mock_logger
    }
  end

  before do
    # Setup mock registry behavior
    allow(mock_registry).to receive(:type_exists?).with("database_tables").and_return(true)
    allow(mock_registry).to receive(:type_exists?).with("model_associations").and_return(true)
    allow(mock_registry).to receive(:type_exists?).with("model_associations_flowchart").and_return(true)
    allow(mock_registry).to receive(:type_exists?).with("invalid_type").and_return(false)

    allow(mock_registry).to receive(:create_analyzer).and_return(mock_analyzer)
    allow(mock_registry).to receive(:create_strategy).and_return(mock_strategy)

    allow(mock_registry).to receive(:available_types_with_metadata).and_return({
                                                                                 "database_tables" => { mermaid_type: "erDiagram" },
                                                                                 "model_associations" => { mermaid_type: "classDiagram" },
                                                                                 "model_associations_flowchart" => { mermaid_type: "flowchart" }
                                                                               })

    # Setup mock analyzer and strategy behavior
    allow(mock_analyzer).to receive(:call).and_return(mock_dataset)

    # Setup mock storage behavior
    allow(Dbwatcher::Storage).to receive_message_chain(:sessions, :find)
      .with(session_id).and_return(mock_session)
    allow(Dbwatcher::Storage).to receive_message_chain(:sessions, :find)
      .with("invalid-id").and_return(nil)
  end

  describe "#call" do
    context "with invalid session" do
      it "returns error response when session doesn't exist" do
        generator = described_class.new(session_id: "invalid-id", diagram_type: "database_tables", options: dependencies)
        result = generator.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Session not found")
      end
    end

    context "with invalid diagram type" do
      it "returns error response when diagram type is invalid" do
        allow(mock_error_handler).to receive(:handle_generation_error).and_return({
                                                                                    success: false,
                                                                                    error: "Unknown diagram type: invalid_type"
                                                                                  })

        generator = described_class.new(session_id: session_id, diagram_type: "invalid_type", options: dependencies)
        result = generator.call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid diagram type")
      end
    end

    context "with database_tables diagram type" do
      it "generates ER diagram content" do
        allow(mock_strategy).to receive(:generate_from_dataset).and_return({
                                                                             success: true,
                                                                             content: "erDiagram\n  User ||--o{ Post : \"has_many\"",
                                                                             type: "erDiagram"
                                                                           })

        generator = described_class.new(session_id: session_id, diagram_type: "database_tables", options: dependencies)
        result = generator.call

        expect(result[:success]).to be true
        expect(result[:content]).to include("erDiagram")
      end
    end

    context "with model_associations diagram type" do
      it "generates class diagram content" do
        allow(mock_strategy).to receive(:generate_from_dataset).and_return({
                                                                             success: true,
                                                                             content: "classDiagram\n  User --> Post : has_many",
                                                                             type: "classDiagram"
                                                                           })

        generator = described_class.new(session_id: session_id, diagram_type: "model_associations", options: dependencies)
        result = generator.call

        expect(result[:success]).to be true
        expect(result[:content]).to include("classDiagram")
      end
    end

    context "with model_associations_flowchart diagram type" do
      it "generates flowchart diagram content" do
        allow(mock_strategy).to receive(:generate_from_dataset).and_return({
                                                                             success: true,
                                                                             content: "flowchart TD\n  User[User]\n  Post[Post]\n  User --> Post",
                                                                             type: "flowchart"
                                                                           })

        generator = described_class.new(session_id: session_id, diagram_type: "model_associations_flowchart", options: dependencies)
        result = generator.call

        expect(result[:success]).to be true
        expect(result[:content]).to include("flowchart TD")
      end
    end
  end

  describe ".available_types" do
    it "returns expected diagram types" do
      # This test should be testing DiagramSystem.available_types, not DiagramGenerator
      registry = instance_double(Dbwatcher::Services::DiagramTypeRegistry)

      # Setup the registry mock
      allow(Dbwatcher::Services::DiagramTypeRegistry).to receive(:new).and_return(registry)
      allow(registry).to receive(:available_types).and_return(
        %w[database_tables model_associations model_associations_flowchart]
      )

      # Test DiagramSystem.available_types
      types = Dbwatcher::Services::DiagramSystem.available_types
      expect(types).to be_a(Array)
      expect(types).to include("database_tables", "model_associations", "model_associations_flowchart")
    end
  end
end
