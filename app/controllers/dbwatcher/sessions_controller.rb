# frozen_string_literal: true

module Dbwatcher
  class SessionsController < BaseController
    before_action :find_session, except: [:index]

    def index
      @sessions = Storage.sessions.all
    end

    def show
      redirect_to changes_session_path(@session.id)
    end

    def changes
      Rails.logger.info "SessionsController#changes: Loading changes for session #{@session.id}"
      @tables_summary = build_tables_summary
      @active_filters = parse_filters
    end

    def summary
      Rails.logger.info "SessionsController#summary: Loading summary for session #{@session.id}"
      @tables_summary = build_tables_summary
      @summary_data = build_summary_stats
    end

    def diagrams
      Rails.logger.info "SessionsController#diagrams: Loading diagrams for session #{@session.id}"
      @tables_summary = build_tables_summary
      @diagram_types = available_diagram_types
    end

    def clear
      clear_storage_with_message(
        -> { Storage.session_storage.clear_all },
        "All sessions",
        sessions_path
      )
    end

    private

    def find_session
      @session = Storage.sessions.find(params[:id])
      handle_not_found("Session", sessions_path) unless @session
    end

    def build_tables_summary
      Storage.sessions.build_tables_summary(@session)
    end

    def build_summary_stats
      service = Dbwatcher::Services::Api::SummaryDataService.new(@session)
      result = service.call
      result[:error] ? {} : result
    end

    def available_diagram_types
      Dbwatcher::Services::Api::DiagramDataService.available_types_with_metadata
    end

    def parse_filters
      {
        table: params[:table],
        operation: params[:operation],
        page: params[:page]&.to_i || 1,
        per_page: params[:per_page]&.to_i || 50
      }.compact
    end
  end
end
