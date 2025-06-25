# frozen_string_literal: true

module Dbwatcher
  module Api
    module V1
      class SessionsController < BaseController
        before_action :find_session, except: [:diagram_types]

        def changes_data
          Rails.logger.info "API::V1::SessionsController#changes_data: Getting changes for session #{@session.id}"

          # Paginated, filtered changes data
          service = Dbwatcher::Services::Api::ChangesDataService.new(@session, filter_params)
          render json: service.call
        end

        def summary_data
          Rails.logger.info "API::V1::SessionsController#summary_data: Getting summary for session #{@session.id}"

          # Aggregated summary statistics
          service = Dbwatcher::Services::Api::SummaryDataService.new(@session)
          render json: service.call
        end

        def diagram_data
          Rails.logger.info "API::V1::SessionsController#diagram_data: Getting diagram for session #{@session.id}"

          # Generated diagram content with caching
          service = Dbwatcher::Services::Api::DiagramDataService.new(@session, params[:type], params)
          result = service.call

          if result[:error]
            render json: { error: result[:error] }, status: :unprocessable_entity
          else
            render json: result
          end
        end

        def diagram_types
          Rails.logger.info "API::V1::SessionsController#diagram_types: Getting available diagram types"

          render json: {
            types: Dbwatcher::Services::Api::DiagramDataService.available_types_with_metadata,
            default_type: "database_tables"
          }
        end

        private

        def find_session
          @session = Storage.sessions.find(params[:id])
          render json: { error: "Session not found" }, status: :not_found unless @session
        end

        def filter_params
          params.permit(:table, :operation, :page, :per_page)
        end
      end
    end
  end
end
