# frozen_string_literal: true

module Dbwatcher
  class TablesController < BaseController
    def index
      @tables = Dbwatcher::Services::TableStatisticsCollector.call
    end

    def show
      @table_name = params[:id]
      @changes = Storage.tables.changes_for(@table_name).all
      @sessions = @changes.map { |c| c[:session_id] }.uniq

      respond_to do |format|
        format.html
        format.json { render json: @changes }
      end
    end

    def changes
      @table_name = params[:id]
      @changes = Storage.tables.changes_for(@table_name).all
      @sessions = extract_session_ids(@changes)
      @records = group_changes_by_record(@changes)
    end

    private

    # These remain as they are simple data extraction helpers
    def extract_session_ids(changes)
      changes.map { |c| c[:session_id] }.uniq
    end

    def group_changes_by_record(changes)
      changes.group_by { |c| c[:record_id] }
    end
  end
end
