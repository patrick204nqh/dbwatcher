# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::VERSION do
  it "has a version number" do
    expect(Dbwatcher::VERSION).not_to be_nil
  end

  it "is a valid semantic version" do
    expect(Dbwatcher::VERSION).to match(/\A\d+\.\d+\.\d+(\.\w+)?\z/)
  end

  it "is a string" do
    expect(Dbwatcher::VERSION).to be_a(String)
  end
end
