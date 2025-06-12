# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Middleware do
  let(:app) { double("app") }
  let(:middleware) { described_class.new(app) }
  let(:env) { { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/users", "QUERY_STRING" => "" } }

  before do
    allow(Dbwatcher.configuration).to receive(:enabled).and_return(true)
    allow(Dbwatcher::Storage).to receive(:save_session)
  end

  describe "middleware definition" do
    let(:middleware_file) { File.join(File.dirname(__FILE__), "../../lib/dbwatcher/middleware.rb") }

    it "exists with proper structure" do
      expect(File.exist?(middleware_file)).to be true

      content = File.read(middleware_file)
      expect(content).to include("class Middleware")
      expect(content).to include("module Dbwatcher")
    end

    it "implements rack interface" do
      content = File.read(middleware_file)
      expect(content).to include("def initialize")
      expect(content).to include("def call")
    end
  end

  describe "#call" do
    context "when dbwatch=true is NOT present in query string" do
      before do
        env["QUERY_STRING"] = "page=1&sort=name"
        allow(app).to receive(:call).with(env).and_return([200, {}, ["OK"]])
      end

      it "does not track database changes" do
        expect(Dbwatcher).not_to receive(:track)
        middleware.call(env)
      end

      it "passes the request through normally" do
        expect(app).to receive(:call).with(env).and_return([200, {}, ["OK"]])
        result = middleware.call(env)
        expect(result).to eq([200, {}, ["OK"]])
      end
    end

    context "when dbwatch=true IS present in query string" do
      before do
        env["QUERY_STRING"] = "page=1&dbwatch=true&sort=name"
        env["REMOTE_ADDR"] = "127.0.0.1"
        env["HTTP_USER_AGENT"] = "Test Browser"
        allow(app).to receive(:call).with(env).and_return([200, {}, ["OK"]])
      end

      it "tracks database changes" do
        expect(Dbwatcher).to receive(:track).with(
          name: "HTTP GET /users",
          metadata: {
            ip: "127.0.0.1",
            user_agent: "Test Browser",
            path: "/users",
            method: "GET"
          }
        ).and_yield
        middleware.call(env)
      end

      it "passes the request through and returns the response" do
        expect(app).to receive(:call).with(env).and_return([200, {}, ["OK"]])
        result = middleware.call(env)
        expect(result).to eq([200, {}, ["OK"]])
      end
    end

    context "when dbwatch=true is the only parameter" do
      before do
        env["QUERY_STRING"] = "dbwatch=true"
        env["REMOTE_ADDR"] = "192.168.1.1"
        env["HTTP_USER_AGENT"] = "Mozilla/5.0"
        allow(app).to receive(:call).with(env).and_return([201, {}, ["Created"]])
      end

      it "tracks database changes" do
        expect(Dbwatcher).to receive(:track).with(
          name: "HTTP GET /users",
          metadata: {
            ip: "192.168.1.1",
            user_agent: "Mozilla/5.0",
            path: "/users",
            method: "GET"
          }
        ).and_yield
        middleware.call(env)
      end
    end

    context "with different HTTP methods and dbwatch=true" do
      before do
        env["QUERY_STRING"] = "dbwatch=true"
        env["REMOTE_ADDR"] = "10.0.0.1"
        env["HTTP_USER_AGENT"] = "API Client"
        allow(app).to receive(:call).with(env).and_return([200, {}, ["OK"]])
      end

      it "tracks POST requests" do
        env["REQUEST_METHOD"] = "POST"
        env["PATH_INFO"] = "/users"

        expect(Dbwatcher).to receive(:track).with(
          name: "HTTP POST /users",
          metadata: {
            ip: "10.0.0.1",
            user_agent: "API Client",
            path: "/users",
            method: "POST"
          }
        ).and_yield
        middleware.call(env)
      end

      it "tracks PUT requests" do
        env["REQUEST_METHOD"] = "PUT"
        env["PATH_INFO"] = "/users/123"

        expect(Dbwatcher).to receive(:track).with(
          name: "HTTP PUT /users/123",
          metadata: {
            ip: "10.0.0.1",
            user_agent: "API Client",
            path: "/users/123",
            method: "PUT"
          }
        ).and_yield
        middleware.call(env)
      end

      it "tracks DELETE requests" do
        env["REQUEST_METHOD"] = "DELETE"
        env["PATH_INFO"] = "/users/456"

        expect(Dbwatcher).to receive(:track).with(
          name: "HTTP DELETE /users/456",
          metadata: {
            ip: "10.0.0.1",
            user_agent: "API Client",
            path: "/users/456",
            method: "DELETE"
          }
        ).and_yield
        middleware.call(env)
      end
    end

    context "when an error occurs during tracking" do
      before do
        env["QUERY_STRING"] = "dbwatch=true"
        allow(Dbwatcher).to receive(:track).and_raise(StandardError, "Tracking failed")
        allow(app).to receive(:call).with(env).and_return([200, {}, ["OK"]])
      end

      it "handles errors gracefully and still processes the request" do
        expect { middleware.call(env) }.not_to raise_error
        expect(app).to have_received(:call).with(env)
      end

      it "warns about the error" do
        expect(middleware).to receive(:warn).with("Dbwatcher middleware error: Tracking failed")
        middleware.call(env)
      end
    end
  end

  describe "#should_track?" do
    it "returns false when query string is nil" do
      env["QUERY_STRING"] = nil
      expect(middleware.send(:should_track?, env)).to be false
    end

    it "returns false when query string is empty" do
      env["QUERY_STRING"] = ""
      expect(middleware.send(:should_track?, env)).to be false
    end

    it "returns false when dbwatch=true is not present" do
      env["QUERY_STRING"] = "page=1&sort=name"
      expect(middleware.send(:should_track?, env)).to be false
    end

    it "returns true when dbwatch=true is present" do
      env["QUERY_STRING"] = "dbwatch=true"
      expect(middleware.send(:should_track?, env)).to be true
    end

    it "returns true when dbwatch=true is present with other params" do
      env["QUERY_STRING"] = "page=1&dbwatch=true&sort=name"
      expect(middleware.send(:should_track?, env)).to be true
    end

    it "returns false when dbwatch=false is present" do
      env["QUERY_STRING"] = "dbwatch=false"
      expect(middleware.send(:should_track?, env)).to be false
    end
  end

  describe "#build_metadata" do
    before do
      env.merge!({
                   "REMOTE_ADDR" => "192.168.1.100",
                   "HTTP_USER_AGENT" => "Test User Agent",
                   "PATH_INFO" => "/api/v1/users",
                   "REQUEST_METHOD" => "POST"
                 })
    end

    it "builds metadata hash with request information" do
      metadata = middleware.send(:build_metadata, env)

      expect(metadata).to eq({
                               ip: "192.168.1.100",
                               user_agent: "Test User Agent",
                               path: "/api/v1/users",
                               method: "POST"
                             })
    end

    it "handles missing environment variables gracefully" do
      env.delete("REMOTE_ADDR")
      env.delete("HTTP_USER_AGENT")

      metadata = middleware.send(:build_metadata, env)

      expect(metadata).to eq({
                               ip: nil,
                               user_agent: nil,
                               path: "/api/v1/users",
                               method: "POST"
                             })
    end
  end
end
