# frozen_string_literal: true

# Base class for query objects
class ApplicationQuery
  def initialize(relation = nil)
    @relation = relation
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  class << self
    def call(*args)
      new(*args).call
    end
  end

  private

  attr_reader :relation

  def default_relation
    raise NotImplementedError, "#{self.class} must implement #default_relation"
  end

  def base_relation
    relation || default_relation
  end
end
