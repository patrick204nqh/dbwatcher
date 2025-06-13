# frozen_string_literal: true

module Dbwatcher
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @sessions = Storage.all_sessions
    end

    def show
      @session = Storage.load_session(params[:id])

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
