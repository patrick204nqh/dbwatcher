# frozen_string_literal: true

module Dbwatcher
  class TablesController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @tables = all_tables_with_stats
    end

    def show
      @table_name = params[:id]
      @changes = Storage.load_table_changes(@table_name)
      @sessions = @changes.map { |c| c["session_id"] }.uniq

      respond_to do |format|
        format.html
        format.json { render json: @changes }
      end
    end

    def changes
      @table_name = params[:id]
      @changes = Storage.load_table_changes(@table_name)

      # Group by record for table view
      @records = @changes.group_by { |c| c["record_id"] }
    end

    private

    def all_tables_with_stats
      tables = initialize_tables_from_schema
      add_change_statistics_to_tables(tables)
      sort_tables_by_change_count(tables)
    end

    def initialize_tables_from_schema
      tables = {}

      # Get all table names from schema if possible
      if defined?(ActiveRecord::Base)
        begin
          ActiveRecord::Base.connection.tables.each do |table|
            tables[table] = { name: table, change_count: 0, last_change: nil }
          end
        rescue StandardError
          # Fallback if connection isn't available
        end
      end

      tables
    end

    def add_change_statistics_to_tables(tables)
      Storage.all_sessions.each do |session_info|
        session = Storage.load_session(session_info[:id])
        next unless session

        update_tables_from_session(tables, session)
      end

      tables
    end

    def update_tables_from_session(tables, session)
      session.changes.each do |change|
        table_name = change["table_name"] || change[:table_name]
        next if table_name.nil? || table_name.empty? # Skip invalid table names

        tables[table_name] ||= { name: table_name, change_count: 0, last_change: nil }
        update_table_statistics(tables[table_name], change)
      end
    end

    def update_table_statistics(table, change)
      table[:change_count] += 1
      timestamp = change["timestamp"] || change[:timestamp]
      table[:last_change] = timestamp if table[:last_change].nil? || timestamp > table[:last_change]
    end

    def sort_tables_by_change_count(tables)
      tables.values.sort_by { |t| -t[:change_count] }
    end
  end
end
