# frozen_string_literal: true

# Base form object for handling form logic
class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  def submit
    return false unless valid?

    process
  rescue StandardError => e
    errors.add(:base, e.message)
    false
  end

  protected

  def process
    raise NotImplementedError, "#{self.class} must implement #process"
  end
end
