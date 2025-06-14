# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include ApplicationConstants

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  # Handle connection issues
  retry_on ActiveRecord::ConnectionNotEstablished, wait: 10.seconds, attempts: 2

  # Add job instrumentation for monitoring
  around_perform do |job, block|
    Rails.logger.info "Starting job: #{job.class.name} with arguments: #{job.arguments}"
    start_time = Time.current

    block.call

    duration = Time.current - start_time
    Rails.logger.info "Completed job: #{job.class.name} in #{duration.round(2)} seconds"
  rescue StandardError => e
    Rails.logger.error "Job failed: #{job.class.name} - #{e.message}"
    raise
  end

  private

  # Helper method for jobs that need database operations
  def with_database_transaction(&)
    ActiveRecord::Base.transaction(&)
  end
end
