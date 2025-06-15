# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Dbwatcher::Storage do
  let(:temp_dir) { Dir.mktmpdir }
  let(:session_id) { "test-session-123" }
  let(:query_id) { "test-query-123" }
  let(:table_name) { "test_table" }

  before do
    allow(Dbwatcher.configuration).to receive(:storage_path).and_return(temp_dir)
    # Reset cached storage instances to pick up the new storage path
    Dbwatcher::Storage.reset_storage_instances!
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "clean API interface" do
    describe "sessions API" do
      let(:session) do
        Dbwatcher::Storage::Session.new(
          id: session_id,
          name: "Test Session",
          changes: [
            {
              "table_name" => "users",
              "operation" => "INSERT",
              "timestamp" => "2024-12-19T10:00:00Z",
              "record_id" => "1"
            }
          ]
        )
      end

      it "can create and find sessions" do
        expect { Dbwatcher::Storage.sessions.create(session) }.not_to raise_error
        loaded_session = Dbwatcher::Storage.sessions.find(session_id)

        expect(loaded_session).not_to be_nil
        expect(loaded_session.id).to eq(session_id)
        expect(loaded_session.name).to eq("Test Session")
      end

      it "handles missing sessions gracefully" do
        result = Dbwatcher::Storage.sessions.find("nonexistent")
        expect(result).to respond_to(:id) # Should return NullSession
      end

      it "can list all sessions" do
        Dbwatcher::Storage.sessions.create(session)
        sessions = Dbwatcher::Storage.sessions.all

        expect(sessions).to be_an(Array)
        expect(sessions.length).to be >= 1
      end

      it "supports fluent interface" do
        Dbwatcher::Storage.sessions.create(session)

        result = Dbwatcher::Storage.sessions.recent(days: 7).limit(10)
        expect(result).to respond_to(:all)

        sessions = result.all
        expect(sessions).to be_an(Array)
      end
    end

    describe "queries API" do
      let(:query) do
        {
          id: query_id,
          sql: "SELECT * FROM users",
          operation: "SELECT",
          duration: 10.5,
          timestamp: Time.now,
          tables: ["users"]
        }
      end

      it "can create queries" do
        expect { Dbwatcher::Storage.queries.create(query) }.not_to raise_error
      end

      it "supports date-based filtering" do
        date = Date.today.strftime("%Y-%m-%d")
        result = Dbwatcher::Storage.queries.for_date(date)

        expect(result).to respond_to(:all)
        queries = result.all
        expect(queries).to be_an(Array)
      end
    end

    describe "tables API" do
      let(:session_with_changes) do
        Dbwatcher::Storage::Session.new(
          id: "session-with-changes",
          name: "Session with Table Changes",
          changes: [
            {
              "table_name" => table_name,
              "operation" => "INSERT",
              "timestamp" => "2024-12-19T10:00:00Z",
              "record_id" => "1"
            },
            {
              "table_name" => table_name,
              "operation" => "UPDATE",
              "timestamp" => "2024-12-19T10:01:00Z",
              "record_id" => "1"
            }
          ]
        )
      end

      it "can get changes for a table" do
        Dbwatcher::Storage.sessions.create(session_with_changes)

        result = Dbwatcher::Storage.tables.changes_for(table_name)
        expect(result).to respond_to(:all)

        changes = result.all
        expect(changes).to be_an(Array)
      end

      it "supports operation filtering" do
        Dbwatcher::Storage.sessions.create(session_with_changes)

        result = Dbwatcher::Storage.tables.changes_for(table_name).by_operation("INSERT")
        changes = result.all

        expect(changes).to be_an(Array)
        # Should only contain INSERT operations
        changes.each do |change|
          expect(change[:operation]).to eq("INSERT")
        end
      end

      it "supports recent filtering" do
        Dbwatcher::Storage.sessions.create(session_with_changes)

        result = Dbwatcher::Storage.tables.changes_for(table_name).recent(days: 1)
        changes = result.all

        expect(changes).to be_an(Array)
      end
    end
  end

  describe "data consistency" do
    it "normalizes mixed string/symbol data" do
      mixed_session = Dbwatcher::Storage::Session.new(
        id: "mixed-session",
        name: "Mixed Data Session",
        changes: [
          {
            :table_name => "users",     # symbol key
            "operation" => "INSERT",    # string key
            :timestamp => "2024-12-19T10:00:00Z"
          }
        ]
      )

      Dbwatcher::Storage.sessions.create(mixed_session)
      changes = Dbwatcher::Storage.tables.changes_for("users").all

      # All returned data should have consistent symbol keys
      changes.each do |change|
        expect(change.keys).to all(be_a(Symbol))
        expect(change[:table_name]).to eq("users")
        expect(change[:operation]).to eq("INSERT")
      end
    end
  end

  describe "cleanup operations" do
    it "can clean up old sessions" do
      expect { Dbwatcher::Storage.cleanup_old_sessions }.not_to raise_error
    end

    it "can reset storage" do
      expect { Dbwatcher::Storage.clear_all }.not_to raise_error
    end
  end

  describe "storage instances" do
    it "provides access to storage instances" do
      expect(Dbwatcher::Storage.session_storage).to respond_to(:save)
      expect(Dbwatcher::Storage.query_storage).to respond_to(:save)
      expect(Dbwatcher::Storage.table_storage).to respond_to(:load_changes)
    end

    it "can reset storage instances" do
      expect { Dbwatcher::Storage.reset_storage_instances! }.not_to raise_error
    end
  end
end
