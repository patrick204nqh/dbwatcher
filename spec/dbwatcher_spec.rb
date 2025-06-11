# frozen_string_literal: true

RSpec.describe Dbwatcher do
  it "has a version number" do
    expect(Dbwatcher::VERSION).not_to be nil
  end

  it "can be configured" do
    Dbwatcher.configure do |config|
      config.enabled = false
    end
    expect(Dbwatcher.configuration.enabled).to eq(false)
  end

  it "can track sessions" do
    result = Dbwatcher.track(name: "test session") do
      "test result"
    end
    expect(result).to eq("test result")
  end
end
