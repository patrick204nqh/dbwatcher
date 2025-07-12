# frozen_string_literal: true

module Dbwatcher
  module Api
    module V1
      class SessionsController < BaseController
        before_action :find_session, except: [:diagram_types]

        def tables_data
          Rails.logger.info "API::V1::SessionsController#tables_data: Getting tables for session #{@session.id}"
          service = Dbwatcher::Services::Api::TablesDataService.new(@session, tables_data_params)
          render json: service.call
        end

        def summary_data
          Rails.logger.info "API::V1::SessionsController#summary_data: Getting summary for session #{@session.id}"
          service = Dbwatcher::Services::Api::SummaryDataService.new(@session)
          render json: service.call
        end

        def diagram_data
          Rails.logger.info "API::V1::SessionsController#diagram_data: Getting diagram for session #{@session.id}"
          service = Dbwatcher::Services::Api::DiagramDataService.new(@session, params[:type], diagram_params)
          result = service.call

          if result[:error]
            render_error(result[:error])
          else
            render json: result
          end
        end

        def timeline_data
          Rails.logger.info "API::V1::SessionsController#timeline_data: Getting timeline for session #{@session.id}"
          service = Dbwatcher::Services::TimelineDataService.new(@session)
          result = service.call

          if result[:errors].any?
            render_error(result[:errors].first[:message])
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
          render_error("Session not found", :not_found) unless @session
        end

        def tables_data_params
          params.permit(:id, :table, :operation, :page, :per_page, session: {}).to_h
        end

        def diagram_params
          params.permit(:type, :format, :include_columns, :show_relationships, session: {}).to_h
        end

        def render_error(message, status = :unprocessable_entity)
          render json: { error: message }, status: status
        end
      end
    end
  end
end
