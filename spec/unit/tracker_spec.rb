# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Tracker do
  describe "tracking functionality" do
    it "works when disabled" do
      allow(Dbwatcher.configuration).to receive(:enabled).and_return(false)

      result = Dbwatcher::Tracker.track { "test result" }
      expect(result).to eq("test result")
    end

    it "works when enabled" do
      allow(Dbwatcher.configuration).to receive(:enabled).and_return(true)
      allow(Dbwatcher::Storage).to receive(:save_session)

      result = Dbwatcher::Tracker.track { "test result" }
      expect(result).to eq("test result")
    end

    it "accepts session options" do
      allow(Dbwatcher.configuration).to receive(:enabled).and_return(true)
      allow(Dbwatcher::Storage).to receive(:save_session)

      expect do
        Dbwatcher::Tracker.track(name: "Custom Session") { "test" }
      end.not_to raise_error
    end
  end

  describe "session management" do
    it "can get current session" do
      session = Dbwatcher::Tracker.current_session
      expect(session).to respond_to(:id) if session
    end

    it "can record changes" do
      expect do
        Dbwatcher::Tracker.record_change({ type: "test", data: "sample" })
      end.not_to raise_error
    end
  end
end
