# frozen_string_literal: true

class TestingController < ApplicationController
  include DatabaseResettable
  include Statisticsable

  # Testing interface index page
  def index
    # Just render the testing interface
  end

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

  # High-volume insert operations - creates many records across tables
  def high_volume_inserts
    handle_database_operation(:high_volume_inserts)
  end

  # High-volume update operations - updates many records across tables
  def high_volume_updates
    handle_database_operation(:high_volume_updates)
  end

  # High-volume delete operations - deletes many records across tables
  def high_volume_deletes
    handle_database_operation(:high_volume_deletes)
  end

  # Mixed high-volume operations - combination of many inserts, updates, and deletes
  def mixed_high_volume_operations
    handle_database_operation(:mixed_high_volume_operations)
  end

  # Batch processing simulation - processes records in batches
  def batch_processing
    handle_database_operation(:batch_processing)
  end

  private

  def handle_database_operation(operation)
    # Wrap operation in DBWatcher tracking to ensure changes are captured
    tracked_result = Dbwatcher.track(
      name: "Testing: #{operation.to_s.humanize}",
      metadata: {
        operation: operation.to_s,
        controller: self.class.name,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    ) do
      Testing::DatabaseOperationsService.call(
        operation: operation,
        params: params
      )
    end

    if tracked_result.success?
      case operation
      when :nested_operations
        redirect_to post_path(tracked_result.data), notice: tracked_result.message
      else
        redirect_to root_path, notice: tracked_result.message
      end
    else
      redirect_to root_path, alert: tracked_result.message
    end
  end
end
