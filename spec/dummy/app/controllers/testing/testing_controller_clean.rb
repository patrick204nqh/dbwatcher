# frozen_string_literal: true

module Testing
  class TestingController < ApplicationController
    include DatabaseResettable
    include Statisticsable

    # Complex transaction with multiple models and relationships
    def complex_transaction
      handle_database_operation(:complex_transaction)
    end

    # Mass updates across multiple tables
    def mass_updates
      handle_database_operation(:mass_updates)
    end

    # Cascade deletes to test relationship handling
    def cascade_deletes
      handle_database_operation(:cascade_deletes)
    end

    # Create with nested associations using accepts_nested_attributes
    def create_with_associations
      handle_database_operation(:nested_operations)
    end

    # Trigger intentional errors for testing error handling
    def trigger_errors
      handle_database_operation(:trigger_errors)
    end

    # Complex nested operations
    def nested_operations
      handle_database_operation(:nested_operations)
    end

    # Bulk operations with different patterns
    def bulk_operations
      handle_database_operation(:bulk_operations)
    end

    # Simulate concurrent updates (for testing race conditions)
    def concurrent_updates
      handle_database_operation(:concurrent_updates)
    end

    # Quick test for rapid iterations
    def quick_test
      result = StatisticsService.call
      render json: result.data
    end

    # Reset all test data to default state
    def reset_data
      reset_database
    end

    private

    def handle_database_operation(operation)
      result = Testing::DatabaseOperationsService.call(
        operation: operation,
        params: params
      )

      if result.success?
        case operation
        when :nested_operations
          redirect_to post_path(result.data), notice: result.message
        else
          redirect_to users_path, notice: result.message
        end
      else
        redirect_to users_path, alert: result.message
      end
    end
  end
end
