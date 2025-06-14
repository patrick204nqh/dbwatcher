# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Dbwatcher::Storage do
  let(:temp_dir) { Dir.mktmpdir }
  let(:session_id) { "test-session-123" }

  before do
    allow(Dbwatcher.configuration).to receive(:storage_path).and_return(temp_dir)
    # Reset cached storage instances to pick up the new storage path
    Dbwatcher::Storage.reset_storage_instances!
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "session management" do
    it "can save and load sessions" do
      session = Dbwatcher::Tracker::Session.new(id: session_id, name: "Test Session")

      expect { Dbwatcher::Storage.save_session(session) }.not_to raise_error
      loaded_session = Dbwatcher::Storage.load_session(session_id)

      expect(loaded_session).not_to be_nil
    end

    it "handles missing sessions gracefully" do
      expect(Dbwatcher::Storage.load_session("nonexistent")).to be_nil
    end

    it "can list all sessions" do
      sessions = Dbwatcher::Storage.all_sessions
      expect(sessions).to be_an(Array)
    end
  end

  describe "cleanup operations" do
    it "can clean up old sessions" do
      expect { Dbwatcher::Storage.send(:cleanup_old_sessions) }.not_to raise_error
    end
  end
end
