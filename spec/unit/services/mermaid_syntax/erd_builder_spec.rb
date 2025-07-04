# frozen_string_literal: true

require "unit/services/diagram_helper"

RSpec.describe Dbwatcher::Services::MermaidSyntax::ErdBuilder do
  let(:entity_class) { Dbwatcher::Services::DiagramData::Entity }
  let(:attribute_class) { Dbwatcher::Services::DiagramData::Attribute }
  let(:relationship_class) { Dbwatcher::Services::DiagramData::Relationship }
  let(:dataset_class) { Dbwatcher::Services::DiagramData::Dataset }

  # Create a simple test entity
  let(:users_entity) do
    entity = entity_class.new(id: "users", name: "users", type: "table")
    entity.attributes << attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true })
    entity.attributes << attribute_class.new(name: "name", type: "string")
    entity
  end

  # Create another test entity with a foreign key
  let(:posts_entity) do
    entity = entity_class.new(id: "posts", name: "posts", type: "table")
    entity.attributes << attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true })
    entity.attributes << attribute_class.new(name: "user_id", type: "integer", metadata: { foreign_key: true })
    entity
  end

  # Create a basic relationship
  let(:one_to_many_relationship) do
    relationship_class.new(
      source_id: "users",
      target_id: "posts",
      type: "foreign_key",
      label: "user_id",
      cardinality: "one_to_many"
    )
  end

  # Create a simple dataset
  let(:simple_dataset) do
    dataset = dataset_class.new
    dataset.add_entity(users_entity)
    dataset.add_entity(posts_entity)
    dataset.add_relationship(one_to_many_relationship)
    dataset
  end

  describe "#build_from_dataset" do
    context "with default configuration" do
      let(:builder) { described_class.new }

      it "generates an ERD diagram with entities and relationships" do
        result = builder.build_from_dataset(simple_dataset)

        # Basic structure
        expect(result).to include("erDiagram")
        expect(result).to include("users {")
        expect(result).to include("posts {")

        # Attributes
        expect(result).to include("integer id PK")
        expect(result).to include("string name")
        expect(result).to include("integer user_id FK")

        # Relationship
        expect(result).to include('users ||--o{ posts : "user_id"')
      end
    end

    context "with attributes disabled" do
      let(:builder) { described_class.new(show_attributes: false) }

      it "does not include attributes in entity definitions" do
        result = builder.build_from_dataset(simple_dataset)

        expect(result).to include("users {")
        expect(result).to include("posts {")
        expect(result).not_to include("integer id PK")
        expect(result).not_to include("string name")
      end
    end

    context "with cardinality options" do
      it "uses correct cardinality notation for one-to-many" do
        builder = described_class.new(show_cardinality: true)
        result = builder.build_from_dataset(simple_dataset)
        expect(result).to include('users ||--o{ posts : "user_id"')
      end

      it "handles different cardinality types" do
        # Create entities and relationships for different cardinality types
        dataset = dataset_class.new
        dataset.add_entity(users_entity)
        dataset.add_entity(posts_entity)

        # Add a profiles entity for one-to-one relationship
        profiles_entity = entity_class.new(id: "profiles", name: "profiles", type: "table")
        dataset.add_entity(profiles_entity)

        # Add one-to-one relationship
        one_to_one = relationship_class.new(
          source_id: "users",
          target_id: "profiles",
          type: "foreign_key",
          label: "user_id",
          cardinality: "one_to_one"
        )
        dataset.add_relationship(one_to_one)

        # Add one-to-many relationship
        dataset.add_relationship(one_to_many_relationship)

        builder = described_class.new
        result = builder.build_from_dataset(dataset)

        expect(result).to include('users ||--|| profiles : "user_id"')
        expect(result).to include('users ||--o{ posts : "user_id"')
      end
    end

    context "with table case options" do
      it "preserves original table case when enabled" do
        builder = described_class.new(preserve_table_case: true)
        result = builder.build_from_dataset(simple_dataset)

        expect(result).to include("users {")
        expect(result).to include("posts {")
      end

      it "converts table names to uppercase when disabled" do
        builder = described_class.new(preserve_table_case: false)
        result = builder.build_from_dataset(simple_dataset)

        expect(result).to include("USERS {")
        expect(result).to include("POSTS {")
      end
    end

    context "with empty dataset" do
      let(:empty_dataset) { dataset_class.new }
      let(:builder) { described_class.new }

      it "generates minimal ERD diagram" do
        result = builder.build_from_dataset(empty_dataset)
        expect(result).to eq("erDiagram")
      end
    end
  end

  describe "#build_empty" do
    let(:builder) { described_class.new }

    it "generates empty ERD with message" do
      result = builder.build_empty("No data available")

      expect(result).to include("erDiagram")
      expect(result).to include("EMPTY_STATE {")
      expect(result).to include('string message "No data available"')
    end
  end
end
