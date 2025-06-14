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
      apply_operation_filter
      apply_table_filter
      apply_duration_filter
    end

    def load_queries_for_date
      Storage.load_queries_for_date(@date)
    end

    def apply_operation_filter
      return unless params[:operation].present?

      @queries = @queries.select { |q| q["operation"] == params[:operation] }
    end

    def apply_table_filter
      return unless params[:table].present?

      @queries = @queries.select { |q| q["tables"]&.include?(params[:table]) }
    end

    def apply_duration_filter
      return unless params[:min_duration].present?

      min_duration = params[:min_duration].to_f
      @queries = @queries.select { |q| q["duration"] && q["duration"] >= min_duration }
    end

    def sort_queries
      @queries = @queries.sort_by { |q| -(q["timestamp"] ? Time.parse(q["timestamp"]).to_i : 0) }
    end
  end
end
