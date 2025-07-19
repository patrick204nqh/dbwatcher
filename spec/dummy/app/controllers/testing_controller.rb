# frozen_string_literal: true

class TestingController < ApplicationController
  include DatabaseResettable
  include Statisticsable

  # Testing interface index page
  def index
    # Just render the testing interface
  end

  # === CORE OPERATIONS ===

  # Basic CRUD operations with relationships
  def basic_operations
    handle_database_operation(:basic_operations)
  end

  # Mass updates across multiple tables
  def mass_updates
    handle_database_operation(:mass_updates)
  end

  # High-volume operations - inserts, updates, deletes
  def high_volume_operations
    handle_database_operation(:mixed_high_volume_operations)
  end

  # === RELATIONSHIP TESTING ===

  # Test all relationship types: has_many, belongs_to, HABTM, has_many_through, polymorphic
  def test_relationships
    handle_database_operation(:test_relationships)
  end

  # === UTILITY OPERATIONS ===

  # Trigger intentional errors for error handling testing
  def trigger_errors
    handle_database_operation(:trigger_errors)
  end

  # Quick database statistics
  def quick_stats
    result = StatisticsService.call
    render json: result.data
  end

  # Reset all test data to default state
  def reset_data
    reset_database
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
