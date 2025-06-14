# frozen_string_literal: true

# Base repository class providing common query methods
class ApplicationRepository
  def initialize(model_class)
    @model_class = model_class
  end

  def find(id)
    model_class.find(id)
  end

  def find_by(conditions)
    model_class.find_by(conditions)
  end

  def where(conditions)
    model_class.where(conditions)
  end

  def all
    model_class.all
  end

  def count
    model_class.count
  end

  def create(attributes)
    model_class.create(attributes)
  end

  def create!(attributes)
    model_class.create!(attributes)
  end

  def update_all(updates)
    model_class.update_all(updates)
  end

  def destroy_all
    model_class.destroy_all
  end

  def includes(*associations)
    model_class.includes(*associations)
  end

  def joins(*associations)
    model_class.joins(*associations)
  end

  def order(ordering)
    model_class.order(ordering)
  end

  def limit(count)
    model_class.limit(count)
  end

  private

  attr_reader :model_class
end
