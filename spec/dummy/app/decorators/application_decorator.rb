# frozen_string_literal: true

# Base decorator class for adding presentation logic to models
class ApplicationDecorator
  def initialize(object)
    @object = object
  end

  private

  attr_reader :object

  def method_missing(method, ...)
    if object.respond_to?(method)
      object.send(method, ...)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    object.respond_to?(method, include_private) || super
  end
end
