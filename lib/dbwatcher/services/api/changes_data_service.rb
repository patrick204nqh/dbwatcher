# frozen_string_literal: true

module Dbwatcher
  module Services
    module Api
      # Service for handling filtered changes data
      #
      # Provides changes data for the sessions changes view and API endpoints
      # with filtering and caching support.
      class ChangesDataService < BaseApiService
        def call
          start_time = Time.now

          # Check for nil session first
          return { error: "Session not found" } unless session

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
            filters: filter_params || {},
            session_id: session.id,
            metadata: build_metadata
          }
        end

        def build_filtered_summary
          summary = Storage.sessions.build_tables_summary(session)

          # Handle nil filter_params
          filter_params_hash = filter_params || {}

          # Apply filters only if they exist
          summary = filter_by_table(summary, filter_params_hash) if filter_params_hash[:table]

          summary = filter_by_operation(summary, filter_params_hash) if filter_params_hash[:operation]

          summary
        end

        def filter_by_table(summary, filter_hash)
          summary.select { |table_name, _| table_name == filter_hash[:table] }
        end

        def filter_by_operation(summary, filter_hash)
          operation = filter_hash[:operation].upcase

          summary.each_value do |data|
            data[:changes] = data[:changes].select do |change|
              change[:operation] == operation
            end
          end

          summary
        end

        def build_metadata
          # Make sure filter_params returns a hash even with nil params
          has_filters = filter_params&.any?

          {
            generated_at: Time.current,
            has_filters: has_filters || false,
            available_tables: available_tables,
            available_operations: %w[INSERT UPDATE DELETE],
            total_count: calculate_total_count
          }
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

          # Handle nil params safely
          if params
            filter_parts << "table_#{params[:table]}" if params[:table]
            filter_parts << "op_#{params[:operation]}" if params[:operation]
          end

          filter_parts.any? ? filter_parts.join("_") : nil
        end
      end
    end
  end
end
