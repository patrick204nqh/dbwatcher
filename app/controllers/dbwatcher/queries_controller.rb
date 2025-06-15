# frozen_string_literal: true

module Dbwatcher
  class QueriesController < BaseController
    def index
      @date = params[:date] || Date.current.strftime("%Y-%m-%d")
      queries = Storage.queries.for_date(@date).all
      @queries = Dbwatcher::Services::QueryFilterProcessor.call(queries, params)

      respond_to do |format|
        format.html
        format.json { render json: @queries }
      end
    end

    def clear
      clear_storage_with_message(
        -> { Storage.query_storage.clear_all },
        "SQL query logs",
        queries_path
      )
    end
  end
end
