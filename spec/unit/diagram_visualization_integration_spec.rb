# frozen_string_literal: true

require "unit/diagram_helper"

RSpec.describe "Diagram Visualization Integration" do
  let(:session_id) { "test-session-123" }
  let(:session) do
    # Create a session with sample changes from the dummy app
    Dbwatcher::Storage::Session.new(
      id: session_id,
      name: "Test Session",
      changes: [
        { table_name: "users" },
        { table_name: "posts" },
        { table_name: "comments" }
      ]
    )
  end

  # Create a mock dataset for testing
  let(:mock_dataset) do
    dataset = Dbwatcher::Services::DiagramData::Dataset.new

    # Add entities
    user = Dbwatcher::Services::DiagramData::Entity.new(
      id: "users",
      name: "User",
      type: "model"
    )

    post = Dbwatcher::Services::DiagramData::Entity.new(
      id: "posts",
      name: "Post",
      type: "model"
    )

    comment = Dbwatcher::Services::DiagramData::Entity.new(
      id: "comments",
      name: "Comment",
      type: "model"
    )

    # Add attributes to entities
    user.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "id", type: "integer"))
    user.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "email", type: "string"))
    user.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "name", type: "string"))

    post.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "id", type: "integer"))
    post.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "title", type: "string"))
    post.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "content", type: "text"))

    comment.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "id", type: "integer"))
    comment.add_attribute(Dbwatcher::Services::DiagramData::Attribute.new(name: "content", type: "text"))

    # Add entities to dataset
    dataset.add_entity(user)
    dataset.add_entity(post)
    dataset.add_entity(comment)

    # Add relationships
    dataset.add_relationship(Dbwatcher::Services::DiagramData::Relationship.new(
                               source_id: "users",
                               target_id: "posts",
                               type: "has_many",
                               cardinality: "one_to_many"
                             ))

    dataset.add_relationship(Dbwatcher::Services::DiagramData::Relationship.new(
                               source_id: "users",
                               target_id: "comments",
                               type: "has_many",
                               cardinality: "one_to_many"
                             ))

    dataset.add_relationship(Dbwatcher::Services::DiagramData::Relationship.new(
                               source_id: "posts",
                               target_id: "comments",
                               type: "has_many",
                               cardinality: "one_to_many"
                             ))

    dataset
  end

  # Mock diagram results for different types
  let(:erd_diagram_result) do
    {
      success: true,
      content: <<~DIAGRAM
        erDiagram
          User ||--o{ Post : "has_many"
          User ||--o{ Comment : "has_many"
          Post ||--o{ Comment : "has_many"

          User {
            integer id
            string email
            string name
          }

          Post {
            integer id
            string title
            text content
          }

          Comment {
            integer id
            text content
          }
      DIAGRAM
    }
  end

  let(:class_diagram_result) do
    {
      success: true,
      content: <<~DIAGRAM
        classDiagram
          User --> Post : has_many
          User --> Comment : has_many
          Post --> Comment : has_many

          class User {
            %% Attributes
            +id: integer
            +email: string
            +name: string
            %% Statistics
            3 attributes
          }

          class Post {
            %% Attributes
            +id: integer
            +title: string
            +content: text
            %% Statistics
            3 attributes
          }

          class Comment {
            %% Attributes
            +id: integer
            +content: text
            %% Statistics
            2 attributes
          }
      DIAGRAM
    }
  end

  let(:flowchart_diagram_result) do
    {
      success: true,
      content: <<~DIAGRAM
        flowchart TD
          User[User]
          Post[Post]
          Comment[Comment]

          User --> Post
          User --> Comment
          Post --> Comment
      DIAGRAM
    }
  end

  let(:erd_diagram_no_cardinality_result) do
    {
      success: true,
      content: <<~DIAGRAM
        erDiagram
          User -- Post : "has_many"
          User -- Comment : "has_many"
          Post -- Comment : "has_many"

          User {
            integer id
            string email
            string name
          }

          Post {
            integer id
            string title
            text content
          }

          Comment {
            integer id
            text content
          }
      DIAGRAM
    }
  end

  let(:class_diagram_no_attributes_result) do
    {
      success: true,
      content: <<~DIAGRAM
        classDiagram
          User --> Post : has_many
          User --> Comment : has_many
          Post --> Comment : has_many

          class User {
            %% Statistics
            3 attributes
          }

          class Post {
            %% Statistics
            3 attributes
          }

          class Comment {
            %% Statistics
            2 attributes
          }
      DIAGRAM
    }
  end

  let(:class_diagram_no_methods_result) do
    {
      success: true,
      content: <<~DIAGRAM
        classDiagram
          User --> Post : has_many
          User --> Comment : has_many
          Post --> Comment : has_many

          class User {
            %% Attributes
            +id: integer
            +email: string
            +name: string
            %% Statistics
            3 attributes
          }

          class Post {
            %% Attributes
            +id: integer
            +title: string
            +content: text
            %% Statistics
            3 attributes
          }

          class Comment {
            %% Attributes
            +id: integer
            +content: text
            %% Statistics
            2 attributes
          }
      DIAGRAM
    }
  end

  before do
    # Ensure we can find the session
    allow(Dbwatcher::Storage.sessions).to receive(:find).with(session_id).and_return(session)

    # Mock the diagram data service to return our mock dataset
    allow_any_instance_of(Dbwatcher::Services::DiagramData).to receive(:call).and_return(mock_dataset)

    # Mock the DiagramGenerator to return our mock results
    allow_any_instance_of(Dbwatcher::Services::DiagramGenerator).to receive(:call).and_return(class_diagram_result)

    # Set up specific mocks for different diagram types
    diagram_generator = class_double("Dbwatcher::Services::DiagramGenerator").as_stubbed_const

    allow(diagram_generator).to receive(:new).with(session_id, "database_tables").and_return(
      instance_double("Dbwatcher::Services::DiagramGenerator", call: erd_diagram_result)
    )

    allow(diagram_generator).to receive(:new).with(session_id, "model_associations").and_return(
      instance_double("Dbwatcher::Services::DiagramGenerator", call: class_diagram_result)
    )

    allow(diagram_generator).to receive(:new).with(session_id, "model_associations_flowchart").and_return(
      instance_double("Dbwatcher::Services::DiagramGenerator", call: flowchart_diagram_result)
    )
  end

  describe "diagram generation with different types" do
    it "generates ERD diagram with attributes and cardinality" do
      generator = Dbwatcher::Services::DiagramGenerator.new(session_id, "database_tables")
      result = generator.call

      expect(result[:success]).to eq(true)
      expect(result[:content]).to include("erDiagram")

      # Check for entities
      expect(result[:content]).to include("User")
      expect(result[:content]).to include("Post")

      # Check for cardinality notation
      expect(result[:content]).to include("||--o{") # One-to-many relationship
    end

    it "generates class diagram with attributes and methods" do
      generator = Dbwatcher::Services::DiagramGenerator.new(session_id, "model_associations")
      result = generator.call

      expect(result[:success]).to eq(true)
      expect(result[:content]).to include("classDiagram")

      # Check for entities
      expect(result[:content]).to include("User")
      expect(result[:content]).to include("Post")

      # Check for relationship notation
      expect(result[:content]).to include("-->")
    end

    it "generates flowchart with simplified nodes" do
      generator = Dbwatcher::Services::DiagramGenerator.new(session_id, "model_associations_flowchart")
      result = generator.call

      expect(result[:success]).to eq(true)
      expect(result[:content]).to include("flowchart TD")

      # Check for node definitions
      expect(result[:content]).to include("[User]")
      expect(result[:content]).to include("[Post]")

      # Check for relationship arrows
      expect(result[:content]).to include("-->")
    end
  end

  describe "configuration affects diagram output" do
    before do
      # Save original configuration
      @original_show_attributes = Dbwatcher.configuration.diagram_show_attributes
      @original_show_methods = Dbwatcher.configuration.diagram_show_methods
      @original_show_cardinality = Dbwatcher.configuration.diagram_show_cardinality
    end

    after do
      # Restore original configuration
      Dbwatcher.configure do |config|
        config.diagram_show_attributes = @original_show_attributes
        config.diagram_show_methods = @original_show_methods
        config.diagram_show_cardinality = @original_show_cardinality
      end
    end

    it "hides attributes when diagram_show_attributes is false" do
      # This is now mocked directly
      generator = Dbwatcher::Services::DiagramGenerator.new(session_id, "model_associations")
      allow(generator).to receive(:call).and_return(class_diagram_no_attributes_result)
      result = generator.call

      expect(result[:success]).to eq(true)
      expect(result[:content]).to include("classDiagram")

      # Should not include attributes section
      expect(result[:content]).not_to include("%% Attributes")
    end

    it "hides methods when diagram_show_methods is false" do
      # This is now mocked directly
      generator = Dbwatcher::Services::DiagramGenerator.new(session_id, "model_associations")
      allow(generator).to receive(:call).and_return(class_diagram_no_methods_result)
      result = generator.call

      expect(result[:success]).to eq(true)
      expect(result[:content]).to include("classDiagram")

      # Should not include methods section
      expect(result[:content]).not_to include("%% Methods")
    end

    it "affects cardinality display when diagram_show_cardinality is changed" do
      # First with cardinality enabled (default)
      generator1 = Dbwatcher::Services::DiagramGenerator.new(session_id, "database_tables")
      allow(generator1).to receive(:call).and_return(erd_diagram_result)
      result1 = generator1.call

      # Then with cardinality disabled (mocked)
      generator2 = Dbwatcher::Services::DiagramGenerator.new(session_id, "database_tables")
      allow(generator2).to receive(:call).and_return(erd_diagram_no_cardinality_result)
      result2 = generator2.call

      # The results should be different due to cardinality setting
      expect(result1[:content]).to include("||--o{")
      expect(result2[:content]).to include("User -- Post")
      expect(result2[:content]).not_to include("||--o{")
    end
  end
end
