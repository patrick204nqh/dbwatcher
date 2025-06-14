# frozen_string_literal: true

# Form object for user creation with profile
class UserCreationForm < ApplicationForm
  attribute :name, :string
  attribute :email, :string
  attribute :age, :integer
  attribute :active, :boolean, default: true
  attribute :salary, :decimal
  attribute :birth_date, :date
  attribute :notes, :string
  attribute :preferences, :string

  # Profile attributes
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :bio, :string
  attribute :website, :string
  attribute :location, :string
  attribute :avatar_url, :string

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0, less_than: 150 }, allow_blank: true
  validates :salary, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  attr_reader :user

  protected

  def process
    result = Users::CreationService.call(user_params)

    if result.success?
      @user = result.data
    else
      result.errors.each { |error| errors.add(:base, error) }
    end

    result.success?
  end

  private

  def user_params
    {
      name: name,
      email: email,
      age: age,
      active: active,
      salary: salary,
      birth_date: birth_date,
      notes: notes,
      preferences: parse_preferences,
      profile_attributes: profile_attributes
    }
  end

  def profile_attributes
    {
      first_name: first_name,
      last_name: last_name,
      bio: bio,
      website: website,
      location: location,
      avatar_url: avatar_url
    }.compact
  end

  def parse_preferences
    return {} if preferences.blank?

    JSON.parse(preferences)
  rescue JSON::ParserError
    {}
  end
end
