# frozen_string_literal: true

# Base command class for encapsulating business logic
class ApplicationCommand
  def initialize(params = {})
    @params = params
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  class << self
    def call(params = {})
      new(params).call
    end
  end

  protected

  attr_reader :params

  def success(data = nil, message = nil)
    CommandResult.new(success: true, data: data, message: message)
  end

  def failure(message = nil, errors = nil)
    CommandResult.new(success: false, message: message, errors: errors)
  end
end

# Result object for command responses
class CommandResult
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
