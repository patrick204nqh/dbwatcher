# frozen_string_literal: true

module Dbwatcher
  module Services
    module Api
      # Service for handling paginated and filtered changes data
      #
      # Provides changes data for the sessions changes view and API endpoints
      # with filtering, pagination, and caching support.
      class ChangesDataService < BaseApiService
        def call
          start_time = Time.now
          log_service_start("Getting changes data for session #{session.id}")

          validation_error = validate_session
          return validation_error if validation_error

          begin
            result = with_cache(cache_suffix) do
              build_changes_response
            end

            log_service_completion(start_time, session_id: session.id, filters: filter_params)
            result
          rescue StandardError => e
            handle_error(e)
          end
        end

        private

        def build_changes_response
          {
            tables_summary: build_filtered_summary,
            pagination: build_pagination_info,
            filters: filter_params,
            session_id: session.id,
            metadata: build_metadata
          }
        end

        def build_filtered_summary
          summary = Storage.sessions.build_tables_summary(session)

          summary = filter_by_table(summary) if filter_params[:table]
          summary = filter_by_operation(summary) if filter_params[:operation]

          summary
        end

        def filter_by_table(summary)
          summary.select { |table_name, _| table_name == filter_params[:table] }
        end

        def filter_by_operation(summary)
          operation = filter_params[:operation].upcase

          summary.each do |table_name, data|
            data[:changes] = data[:changes].select do |change|
              change[:operation] == operation
            end
          end

          summary
        end

        def build_pagination_info
          pagination_params.merge(
            total_pages: calculate_total_pages,
            total_count: calculate_total_count
          )
        end

        def build_metadata
          {
            generated_at: Time.current,
            has_filters: filter_params.any?,
            available_tables: available_tables,
            available_operations: %w[INSERT UPDATE DELETE]
          }
        end

        def calculate_total_pages
          total = calculate_total_count
          per_page = pagination_params[:per_page]
          (total.to_f / per_page).ceil
        end

        def calculate_total_count
          summary = Storage.sessions.build_tables_summary(session)
          summary.values.sum { |data| data[:changes]&.length || 0 }
        end

        def available_tables
          summary = Storage.sessions.build_tables_summary(session)
          summary.keys
        end

        def cache_suffix
          filter_parts = []
          filter_parts << "table_#{filter_params[:table]}" if filter_params[:table]
          filter_parts << "op_#{filter_params[:operation]}" if filter_params[:operation]
          filter_parts << "page_#{pagination_params[:page]}" if pagination_params[:page] > 1

          filter_parts.any? ? filter_parts.join("_") : nil
        end
      end
    end
  end
end
