# frozen_string_literal: true

module Dbwatcher
  class QueriesController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @date = params[:date] || Date.current.strftime("%Y-%m-%d")
      queries = Storage.queries.for_date(@date).all
      @queries = Dbwatcher::Services::QueryFilterProcessor.call(queries, params)

      respond_to do |format|
        format.html
        format.json { render json: @queries }
      end
    end
  end
end
