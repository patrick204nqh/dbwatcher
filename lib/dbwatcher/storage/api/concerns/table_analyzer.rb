# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Api
      module Concerns
        # Provides reusable table analysis functionality for API classes
        #
        # This concern now acts as a facade, delegating specific responsibilities
        # to specialized service classes while maintaining backward compatibility.
        #
        # @example
        #   class MyAPI < BaseAPI
        #     include Api::Concerns::TableAnalyzer
        #
        #     def analyze(session)
        #       build_tables_summary(session)
        #     end
        #   end
        module TableAnalyzer
          # Build tables summary from session changes
          #
          # @param session [Session] session to analyze
          # @return [Hash] tables summary hash
          def build_tables_summary(session)
            # Delegate to new service while maintaining interface compatibility
            Dbwatcher::Services::Analyzers::TableSummaryBuilder.call(session)
          end

          # Process all changes in a session (legacy method for backward compatibility)
          #
          # @param session [Session] session with changes
          # @param _tables [Hash] tables hash to populate (unused but kept for compatibility)
          # @return [void]
          def process_session_changes(session, _tables)
            # Use new service for processing but maintain yield interface
            processor = Dbwatcher::Services::Analyzers::SessionDataProcessor.new(session)
            processor.process_changes do |table_name, change, _|
              yield(table_name, change) if block_given?
            end
          end

          # Legacy methods maintained for backward compatibility
          # These now delegate to the new service classes

          # Extract table name from change data (legacy compatibility)
          #
          # @param change [Hash] change data
          # @return [String, nil] table name or nil
          def extract_table_name(change)
            return nil unless change.is_a?(Hash)

            change[:table_name]
          end
        end
      end
    end
  end
end
