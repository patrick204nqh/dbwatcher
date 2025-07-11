# frozen_string_literal: true

module Dbwatcher
  class SessionsController < BaseController
    before_action :find_session, except: [:index]

    def index
      @sessions = Storage.sessions.all
    end

    def show
      @active_tab = params[:tab] || "tables"
      # Debug logging
      Rails.logger.info "SessionsController#show: Session ID: #{@session.id.inspect}, Class: #{@session.class}"
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
  end
end
