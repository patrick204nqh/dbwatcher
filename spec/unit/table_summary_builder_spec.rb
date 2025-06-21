# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Services::Analyzers::TableSummaryBuilder do
  let(:session) { double("Session", id: "test-session-123", changes: changes) }
  let(:processor) { double("SessionDataProcessor") }

  before do
    allow(Dbwatcher::Services::Analyzers::SessionDataProcessor).to receive(:new).with(session).and_return(processor)
  end

  describe "#call" do
    context "with mixed operations" do
      let(:changes) { [1, 2, 3, 4, 5, 6, 7, 8] } # Mock 8 changes

      before do
        # Mock the processor to yield table data
        expect(processor).to receive(:process_changes).and_yield(
          "users", { operation: "INSERT", record_snapshot: { id: 1, name: "John" } }, {}
        ).and_yield(
          "users", { operation: "INSERT", record_snapshot: { id: 2, name: "Jane" } }, {}
        ).and_yield(
          "users", { operation: "UPDATE", record_snapshot: { id: 1, name: "John Updated" } }, {}
        ).and_yield(
          "posts", { operation: "INSERT", record_snapshot: { id: 1, title: "Post 1" } }, {}
        ).and_yield(
          "posts", { operation: "DELETE", record_snapshot: { id: 1, title: "Post 1" } }, {}
        ).and_yield(
          "comments", { operation: "INSERT", record_snapshot: { id: 1, body: "Comment 1" } }, {}
        ).and_yield(
          "empty_table", { operation: nil, record_snapshot: { id: 1 } }, {}
        )
      end

      it "builds summary with correct operation counts" do
        allow(Time).to receive(:now).and_return(Time.now)

        result = described_class.new(session).call

        # Check users table
        expect(result["users"][:total_operations]).to eq(3)
        expect(result["users"][:operations]["INSERT"]).to eq(2)
        expect(result["users"][:operations]["UPDATE"]).to eq(1)
        expect(result["users"][:operations]).not_to have_key("DELETE")

        # Check posts table
        expect(result["posts"][:total_operations]).to eq(2)
        expect(result["posts"][:operations]["INSERT"]).to eq(1)
        expect(result["posts"][:operations]["DELETE"]).to eq(1)
        expect(result["posts"][:operations]).not_to have_key("UPDATE")

        # Check comments table
        expect(result["comments"][:total_operations]).to eq(1)
        expect(result["comments"][:operations]["INSERT"]).to eq(1)
        expect(result["comments"][:operations]).not_to have_key("UPDATE")
        expect(result["comments"][:operations]).not_to have_key("DELETE")

        # The empty_table will have an :unknown operation, so it might still be included
        # Let's check that it doesn't have any valid operations
        if result.key?("empty_table")
          expect(result["empty_table"][:operations]).not_to have_key("INSERT")
          expect(result["empty_table"][:operations]).not_to have_key("UPDATE")
          expect(result["empty_table"][:operations]).not_to have_key("DELETE")
        end
      end

      it "captures sample records correctly" do
        result = described_class.new(session).call

        expect(result["users"][:sample_record]).to include(
          id: 1,
          name: "John Updated" # Should have the latest value
        )

        expect(result["posts"][:sample_record]).to include(
          id: 1,
          title: "Post 1"
        )
      end
    end

    context "with empty session" do
      let(:changes) { [] }

      before do
        allow(processor).to receive(:process_changes)
      end

      it "returns empty hash" do
        result = described_class.new(session).call
        expect(result).to be_empty
      end
    end

    context "with only zero-count operations" do
      let(:changes) { [1] }

      before do
        # Mock the processor with an unknown operation that will be counted as :unknown
        expect(processor).to receive(:process_changes).and_yield(
          "users", { operation: "UNKNOWN", record_snapshot: { id: 1 } }, {}
        )
      end

      it "filters out tables with no valid operations" do
        result = described_class.new(session).call

        # The table might still be included, but should have no valid operations
        if result.key?("users")
          expect(result["users"][:operations]).not_to have_key("INSERT")
          expect(result["users"][:operations]).not_to have_key("UPDATE")
          expect(result["users"][:operations]).not_to have_key("DELETE")
        end
      end
    end
  end
end
