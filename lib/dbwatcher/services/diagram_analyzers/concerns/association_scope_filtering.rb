# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      module Concerns
        # Concern for filtering associations based on scope
        #
        # This module provides methods for determining which associations
        # should be included in the analysis based on session context.
        module AssociationScopeFiltering
          extend ActiveSupport::Concern if defined?(ActiveSupport)

          private

          # Check if target model is in analysis scope
          #
          # @param association [Object] association object
          # @param session_tables [Array<String>] tables from session context
          # @return [Boolean] true if target model should be included
          def target_model_in_scope?(association, session_tables = [])
            target_table = get_association_table_name(association)

            # If analyzing session, both tables must be in session
            # If analyzing globally, include all
            return true if session_tables.empty?

            # Skip if target table is not in session
            return false if target_table && !session_tables.include?(target_table)

            true
          end

          # Get table name for association target
          #
          # @param association [Object] association object
          # @return [String, nil] table name
          def get_association_table_name(association)
            association.table_name
          rescue StandardError => e
            Rails.logger.warn "#{self.class.name}: Could not get table name for #{association.name}: #{e.message}"
            nil
          end

          # Extract tables that were involved in the session
          #
          # @param session [Object] session object with changes
          # @return [Array<String>] unique table names
          def extract_session_tables(session)
            return [] unless session&.changes

            session.changes.map do |change|
              change[:table_name] || change["table_name"]
            end.compact.uniq
          end
        end
      end
    end
  end
end
