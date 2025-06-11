# frozen_string_literal: true

module Dbwatcher
  class Configuration
    attr_accessor :storage_path, :enabled, :max_sessions, :auto_clean_after_days

    def initialize
      @storage_path = default_storage_path
      @enabled = true
      @max_sessions = 100
      @auto_clean_after_days = 7
    end

    private

    def default_storage_path
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        Rails.root.join("tmp", "dbwatcher").to_s
      else
        File.join(Dir.pwd, "tmp", "dbwatcher")
      end
    end
  end
end
