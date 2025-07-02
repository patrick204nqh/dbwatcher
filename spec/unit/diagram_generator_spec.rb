# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::DiagramGenerator do
  let(:session) do
    # Create a session with sample changes from the dummy app
    Dbwatcher::Storage::Session.new(
      id: "test-session-123",
      name: "Test Session",
      changes: [
        { table_name: "users" },
        { table_name: "posts" },
        { table_name: "comments" }
      ]
    )
  end

  before do
    # Ensure we can find the session
    allow(Dbwatcher::Storage.sessions).to receive(:find).with(session.id).and_return(session)

    # Explicitly load the models to ensure they're available
    require_relative "../dummy/app/models/user"
    require_relative "../dummy/app/models/post"
    require_relative "../dummy/app/models/comment"
  end

  describe "#call" do
    context "with invalid session" do
      it "returns error response when session doesn't exist" do
        allow(Dbwatcher::Storage.sessions).to receive(:find).with("invalid-session").and_raise(StandardError)

        generator = described_class.new("invalid-session")
        result = generator.call

        expect(result[:success]).to eq(false)
        expect(result[:error]).to eq("Session not found")
        expect(result[:content]).to be_nil
        expect(result[:type]).to be_nil
        expect(result).to have_key(:generated_at)
      end
    end

    context "with invalid diagram type" do
      it "returns error response when diagram type is invalid" do
        generator = described_class.new(session.id, "invalid_type")
        result = generator.call

        expect(result[:success]).to eq(false)
        expect(result[:error]).to eq(true)
        expect(result[:message]).to be_present
        expect(result[:error_code]).to be_present
        expect(result).to have_key(:timestamp)
      end
    end

    context "with database_tables diagram type" do
      let(:generator) { described_class.new(session.id, "database_tables") }

      it "generates ER diagram content" do
        result = generator.call

        # The success response structure
        expect(result[:success]).to eq(true)
        expect(result[:content]).to include("erDiagram")
        expect(result[:type]).to eq("erDiagram")
        expect(result).to have_key(:generated_at)
      end
    end

    context "with model_associations diagram type" do
      let(:generator) { described_class.new(session.id, "model_associations") }

      it "generates model graph content" do
        result = generator.call

        # The success response structure
        expect(result[:success]).to eq(true)
        expect(result[:content]).to include("flowchart TD")
        expect(result[:type]).to eq("flowchart")
        expect(result).to have_key(:generated_at)
      end

      it "includes model relationships from the dummy app" do
        result = generator.call
        content = result[:content]

        # The diagram should include the actual model relationships from the dummy app
        # Models are represented as nodes with IDs, so we check for their names in quotes
        expect(content).to include('"User"')        # User model node
        expect(content).to include('"Post"')        # Post model node
        expect(content).to include('"Comment"')     # Comment model node

        # Should include association names in edge labels (arrow format)
        expect(content).to include("-->|user|")        # Post/Comment belongs_to user
        expect(content).to include("-->|post|")        # Comment belongs_to post

        # Should include relationship arrows
        expect(content).to include("-->") # Basic relationship arrows

        # Should include node definitions and relationships
        expect(content).to include("node_") # Node IDs are generated
      end
    end
  end

  describe ".available_types" do
    it "returns expected diagram types" do
      types = described_class.available_types

      expect(types).to include("database_tables")
      expect(types).to include("model_associations")
      expect(types["database_tables"][:mermaid_type]).to eq("erDiagram")
      expect(types["model_associations"][:mermaid_type]).to eq("flowchart")
    end
  end
end
