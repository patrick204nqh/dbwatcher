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

        # The error response structure is { error: message }
        expect(result[:error]).to eq("Session not found")
        expect(result).to have_key(:generated_at)
      end
    end

    context "with invalid diagram type" do
      it "returns error response when diagram type is invalid" do
        generator = described_class.new(session.id, "invalid_type")
        result = generator.call

        # The error response structure is { error: message }
        expect(result[:error]).to eq("Invalid diagram type")
        expect(result).to have_key(:generated_at)
      end
    end

    context "with database_tables diagram type" do
      let(:generator) { described_class.new(session.id, "database_tables") }

      it "generates ER diagram content" do
        result = generator.call

        # The success response doesn't have an error key
        expect(result[:error]).to be_nil
        expect(result[:content]).to include("erDiagram")
        expect(result[:type]).to eq("erDiagram")
        expect(result).to have_key(:generated_at)
      end
    end

    context "with model_associations diagram type" do
      let(:generator) { described_class.new(session.id, "model_associations") }

      it "generates model graph content" do
        result = generator.call

        # The success response doesn't have an error key
        expect(result[:error]).to be_nil
        expect(result[:content]).to include("flowchart LR")
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

        # Should include association names in edge labels (without quotes)
        expect(content).to include("|posts|")       # User has_many posts
        expect(content).to include("|comments|")    # User/Post has_many comments
        expect(content).to include("|user|")        # Post/Comment belongs_to user
        expect(content).to include("|post|")        # Comment belongs_to post

        # Should include relationship arrows
        expect(content).to include("-->") # Basic relationship arrows

        # Should include style definitions
        expect(content).to include("style") # Node styling
      end
    end
  end

  describe ".available_types" do
    it "returns expected diagram types" do
      types = described_class.available_types

      expect(types).to include("database_tables")
      expect(types).to include("model_associations")
      expect(types["database_tables"][:type]).to eq("erDiagram")
      expect(types["model_associations"][:type]).to eq("flowchart")
    end
  end
end
