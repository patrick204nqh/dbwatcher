# frozen_string_literal: true

module Dbwatcher
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @sessions = Storage.all_sessions
    end

    def show
      log_session_loading
      @session = load_session

      return handle_session_not_found unless @session

      prepare_session_data
      render_response
    end

    def log_session_loading
      Rails.logger.info "SessionsController#show: Loading session with ID: #{params[:id]}"
    end

    def load_session
      session = Storage.load_session(params[:id])
      Rails.logger.info "SessionsController#show: Loaded session: #{session.inspect}"
      session
    end

    def handle_session_not_found
      Rails.logger.warn "SessionsController#show: Session not found for ID: #{params[:id]}"
      redirect_to sessions_path, alert: "Session not found"
    end

    def prepare_session_data
      @tables_summary = build_tables_summary(@session)
      Rails.logger.info "SessionsController#show: Tables summary: #{@tables_summary.inspect}"
    end

    def render_response
      respond_to do |format|
        format.html
        format.json { render json: @session.to_h }
      end
    end

    def destroy_all
      Dbwatcher.reset!
      redirect_to root_path, notice: "All sessions cleared"
    end

    private

    # Build tables summary in the format expected by the view
    def build_tables_summary(session)
      tables = {}
      process_session_changes(session, tables)
      tables
    end

    def process_session_changes(session, tables)
      session.changes.each do |change|
        table_name = extract_table_name(change)
        initialize_table_data(tables, table_name)
        update_table_data(tables[table_name], change)
        update_sample_record(tables[table_name], change)
      end
    end

    def extract_table_name(change)
      change["table_name"] || change[:table_name]
    end

    def initialize_table_data(tables, table_name)
      tables[table_name] ||= {
        operations: { "INSERT" => 0, "UPDATE" => 0, "DELETE" => 0 },
        changes: [],
        sample_record: nil
      }
    end

    def update_table_data(table_data, change)
      # Count operations
      operation = change["operation"] || change[:operation]
      table_data[:operations][operation] += 1

      # Add change to the list
      table_data[:changes] << change
    end

    def update_sample_record(table_data, change)
      return unless table_data[:sample_record].nil? && (change["record_snapshot"] || change[:record_snapshot])

      snapshot = change["record_snapshot"] || change[:record_snapshot]
      # Convert symbol keys to strings for humanize to work
      table_data[:sample_record] = snapshot.is_a?(Hash) ? stringify_keys(snapshot) : snapshot
    end

    # Helper to convert symbol keys to string keys recursively
    def stringify_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.transform_keys(&:to_s)
    end

    # Helper method to safely get the sessions path
    def sessions_index_path
      if respond_to?(:sessions_path)
        sessions_path
      else
        "/dbwatcher"
      end
    end
    helper_method :sessions_index_path
  end
end
