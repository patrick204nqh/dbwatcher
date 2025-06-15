# frozen_string_literal: true

module Dbwatcher
  class SessionsController < BaseController
    def index
      @sessions = Storage.sessions.all
    end

    def show
      Rails.logger.info "SessionsController#show: Loading session with ID: #{params[:id]}"
      @session = Storage.sessions.find(params[:id])
      Rails.logger.info "SessionsController#show: Loaded session: #{@session.inspect}"

      return handle_not_found("Session", sessions_path) unless @session

      @tables_summary = Storage.sessions.build_tables_summary(@session)
      Rails.logger.info "SessionsController#show: Tables summary: #{@tables_summary.inspect}"

      respond_to do |format|
        format.html
        format.json { render json: @session.to_h }
      end
    end

    def clear
      clear_storage_with_message(
        -> { Storage.session_storage.clear_all },
        "All sessions",
        sessions_path
      )
    end
  end
end
