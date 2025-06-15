# frozen_string_literal: true

module Dbwatcher
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @sessions = Storage.sessions.all
    end

    def show
      Rails.logger.info "SessionsController#show: Loading session with ID: #{params[:id]}"
      @session = Storage.sessions.find(params[:id])
      Rails.logger.info "SessionsController#show: Loaded session: #{@session.inspect}"

      return handle_session_not_found unless @session

      @tables_summary = Storage.sessions.build_tables_summary(@session)
      Rails.logger.info "SessionsController#show: Tables summary: #{@tables_summary.inspect}"

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

    def handle_session_not_found
      Rails.logger.warn "SessionsController#show: Session not found for ID: #{params[:id]}"
      redirect_to sessions_path, alert: "Session not found"
    end
  end
end
