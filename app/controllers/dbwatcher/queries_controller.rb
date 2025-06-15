# frozen_string_literal: true

module Dbwatcher
  class QueriesController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @date = params[:date] || Date.current.strftime("%Y-%m-%d")
      load_and_filter_queries
      sort_queries

      respond_to do |format|
        format.html
        format.json { render json: @queries }
      end
    end

    private

    def load_and_filter_queries
      @queries = load_queries_for_date
                 .then { |queries| filter_by_operation(queries) }
                 .then { |queries| filter_by_table(queries) }
                 .then { |queries| filter_by_duration(queries) }
    end

    def load_queries_for_date
      Storage.queries.for_date(@date).all
    end

    def filter_by_operation(queries)
      return queries unless params[:operation].present?

      queries.select { |q| q[:operation] == params[:operation] }
    end

    def filter_by_table(queries)
      return queries unless params[:table].present?

      queries.select { |q| q[:tables]&.include?(params[:table]) }
    end

    def filter_by_duration(queries)
      return queries unless params[:min_duration].present?

      min_duration = params[:min_duration].to_f
      queries.select { |q| query_meets_duration_threshold?(q, min_duration) }
    end

    def query_meets_duration_threshold?(query, min_duration)
      duration = query[:duration]
      duration && duration >= min_duration
    end

    def sort_queries
      @queries = @queries.sort_by { |q| -(q[:timestamp] ? Time.parse(q[:timestamp]).to_i : 0) }
    end
  end
end
