# frozen_string_literal: true

module Dbwatcher
  class SqlLogger
    include Singleton

    attr_reader :queries

    def initialize
      @queries = []
      @mutex = Mutex.new
      setup_subscriber if Dbwatcher.configuration.track_queries
    end

    def log_query(sql, name, binds, _type_casted_binds, duration)
      return unless Dbwatcher.configuration.track_queries

      @mutex.synchronize do
        query = create_query_record(sql, name, binds, duration)
        store_query(query)
      end
    end

    def create_query_record(sql, name, binds, duration)
      {
        id: SecureRandom.uuid,
        sql: sql,
        name: name,
        binds: binds,
        duration: duration,
        timestamp: Time.current,
        session_id: current_session_id,
        backtrace: filtered_backtrace,
        tables: extract_tables(sql),
        operation: extract_operation(sql)
      }
    end

    def store_query(query)
      @queries << query
      Storage.save_query(query)
    end

    def clear_queries
      @mutex.synchronize do
        @queries.clear
      end
    end

    private

    def setup_subscriber
      ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, start, finish, _id, payload|
        next if skip_query?(payload)

        duration = (finish - start) * 1000.0
        log_query(
          payload[:sql],
          payload[:name],
          payload[:binds],
          payload[:type_casted_binds],
          duration
        )
      end
    end
    
    def skip_query?(payload)
      skip_schema_query?(payload) || skip_internal_query?(payload)
    end
    
    def skip_schema_query?(payload)
      payload[:name]&.include?("SCHEMA")
    end
    
    def skip_internal_query?(payload)
      return true if payload[:sql]&.include?("sqlite_master")
      return true if payload[:sql]&.include?("PRAGMA")
      return true if payload[:sql]&.include?("information_schema")
      
      false
    end

    def extract_tables(sql)
      # Extract table names from SQL
      tables = []
      # Match FROM, JOIN, INTO, UPDATE, DELETE FROM patterns
      sql.scan(/(?:FROM|JOIN|INTO|UPDATE|DELETE\s+FROM)\s+["`]?(\w+)["`]?/i) do |match|
        tables << match[0]
      end
      tables.uniq
    end

    def extract_operation(sql)
      sql.strip.split(/\s+/).first.upcase
    end

    def filtered_backtrace
      caller.select { |line| line.include?(Rails.root.to_s) }
            .reject { |line| line.include?("dbwatcher") }
            .first(5)
    end

    def current_session_id
      Tracker.current_session&.id
    end
  end
end
