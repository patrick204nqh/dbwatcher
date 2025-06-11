# frozen_string_literal: true

module Dbwatcher
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if should_track?(env)
        Dbwatcher.track(
          name: "HTTP #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}",
          metadata: build_metadata(env)
        ) do
          @app.call(env)
        end
      else
        @app.call(env)
      end
    rescue => e
      warn "Dbwatcher middleware error: #{e.message}"
      @app.call(env)
    end

    private

    def should_track?(env)
      env["QUERY_STRING"]&.include?("dbwatch=true")
    end

    def build_metadata(env)
      {
        ip: env["REMOTE_ADDR"],
        user_agent: env["HTTP_USER_AGENT"],
        path: env["PATH_INFO"],
        method: env["REQUEST_METHOD"]
      }
    end
  end
end
