# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Storage::Api::Concerns::TableAnalyzer do
  let(:test_class) do
    Class.new do
      include Dbwatcher::Storage::Api::Concerns::TableAnalyzer
    end
  end
  let(:analyzer) { test_class.new }

  describe "#build_tables_summary" do
    context "with mixed operations having different column sets" do
      let(:session) do
        Dbwatcher::Storage::Session.new(
          id: "test-session",
          name: "Mixed Operations Session",
          changes: [
            # INSERT with full set of columns
            {
              table_name: "users",
              operation: "INSERT",
              timestamp: "2024-12-19T10:00:00Z",
              record_id: "1",
              record_snapshot: { id: 1, name: "John", email: "john@example.com", age: 30 }
            },
            # UPDATE with partial columns (missing age)
            {
              table_name: "users",
              operation: "UPDATE",
              timestamp: "2024-12-19T10:01:00Z",
              record_id: "2",
              record_snapshot: { id: 2, name: "Jane", email: "jane@example.com" }
            },
            # Another INSERT with different column order
            {
              table_name: "users",
              operation: "INSERT",
              timestamp: "2024-12-19T10:02:00Z",
              record_id: "3",
              record_snapshot: { email: "bob@example.com", name: "Bob", age: 25, id: 3 }
            },
            # UPDATE adding a new column not seen before
            {
              table_name: "users",
              operation: "UPDATE",
              timestamp: "2024-12-19T10:03:00Z",
              record_id: "4",
              record_snapshot: { id: 4, name: "Alice", email: "alice@example.com", age: 28, status: "active" }
            }
          ]
        )
      end

      it "maintains consistent column order across all operations" do
        summary = analyzer.build_tables_summary(session)
        users_summary = summary["users"]

        expect(users_summary).not_to be_nil
        expect(users_summary[:sample_record]).not_to be_nil

        # The column order should be established by the first record
        # and maintained throughout, with new columns appended at the end
        expected_keys = %i[id name email age status]
        actual_keys = users_summary[:sample_record].keys

        expect(actual_keys).to eq(expected_keys)
      end

      it "includes all columns from all operations" do
        summary = analyzer.build_tables_summary(session)
        users_summary = summary["users"]
        sample_record = users_summary[:sample_record]

        # All unique columns should be present
        expect(sample_record.keys).to include(:id, :name, :email, :age, :status)
        expect(sample_record.keys.size).to eq(5)
      end

      it "stores consistent column information" do
        summary = analyzer.build_tables_summary(session)
        users_summary = summary["users"]

        expect(users_summary).not_to be_nil
        expect(users_summary[:sample_record]).not_to be_nil

        # The sample record should maintain consistent ordering
        actual_keys = users_summary[:sample_record].keys
        expect(actual_keys).to include(:id, :name, :email, :age, :status)
        expect(actual_keys.size).to eq(5)
      end

      it "handles different tables independently" do
        # Add changes for a different table
        multi_table_session = Dbwatcher::Storage::Session.new(
          id: "multi-table-session",
          name: "Multi Table Session",
          changes: session.changes + [
            {
              table_name: "posts",
              operation: "INSERT",
              timestamp: "2024-12-19T10:04:00Z",
              record_id: "1",
              record_snapshot: { title: "Post 1", content: "Content 1", id: 1 }
            },
            {
              table_name: "posts",
              operation: "UPDATE",
              timestamp: "2024-12-19T10:05:00Z",
              record_id: "2",
              record_snapshot: { id: 2, title: "Post 2", content: "Content 2", published: true }
            }
          ]
        )

        summary = analyzer.build_tables_summary(multi_table_session)

        # Users table should maintain its column order
        users_columns = summary["users"][:sample_record].keys
        expect(users_columns).to eq(%i[id name email age status])

        # Posts table should have its own column order
        posts_columns = summary["posts"][:sample_record].keys
        expect(posts_columns).to eq(%i[title content id published])
      end
    end

    context "with records having nil values" do
      let(:session_with_nils) do
        Dbwatcher::Storage::Session.new(
          id: "session-with-nils",
          name: "Session with Nil Values",
          changes: [
            {
              table_name: "products",
              operation: "INSERT",
              timestamp: "2024-12-19T10:00:00Z",
              record_id: "1",
              record_snapshot: { id: 1, name: "Product 1", price: 100, description: nil }
            },
            {
              table_name: "products",
              operation: "UPDATE",
              timestamp: "2024-12-19T10:01:00Z",
              record_id: "2",
              record_snapshot: { id: 2, name: "Product 2", description: "Updated description" }
            }
          ]
        )
      end

      it "handles nil values correctly while maintaining column order" do
        summary = analyzer.build_tables_summary(session_with_nils)
        products_summary = summary["products"]

        expect(products_summary[:sample_record].keys).to eq(%i[id name price description])
        expect(products_summary[:sample_record][:description]).to eq("Updated description")
      end
    end
  end
end
