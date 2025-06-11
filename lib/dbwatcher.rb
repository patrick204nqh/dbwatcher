# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"
require_relative "dbwatcher/version"
require_relative "dbwatcher/configuration"
require_relative "dbwatcher/tracker"
require_relative "dbwatcher/storage"
require_relative "dbwatcher/model_extension"
require_relative "dbwatcher/middleware"
require_relative "dbwatcher/engine" if defined?(Rails)

module Dbwatcher
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def track(name: nil, metadata: {}, &block)
      Tracker.track(name: name, metadata: metadata, &block)
    end

    def current_session
      Tracker.current_session
    end

    def reset!
      Storage.reset!
    end
  end
end
