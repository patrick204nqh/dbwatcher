# frozen_string_literal: true

# Base service class providing common patterns and utilities
class ApplicationService
  class << self
    def call(*args, **kwargs)
      new(*args, **kwargs).call
    end
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  # Result object for consistent return values
  def success(data = nil, message = nil)
    ServiceResult.new(success: true, data: data, message: message)
  end

  def failure(message = nil, errors = nil)
    ServiceResult.new(success: false, message: message, errors: errors)
  end
end

# Result object for service responses
class ServiceResult
  attr_reader :data, :message, :errors

  def initialize(success:, data: nil, message: nil, errors: nil)
    @success = success
    @data = data
    @message = message
    @errors = errors || []
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
