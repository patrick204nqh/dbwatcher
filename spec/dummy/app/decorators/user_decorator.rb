# frozen_string_literal: true

# Decorator for User presentation logic
class UserDecorator < ApplicationDecorator
  def display_name
    full_name.presence || name
  end

  def status_badge
    active? ? "✅ Active" : "❌ Inactive"
  end

  def formatted_salary
    return "Not specified" unless salary

    "$#{salary.to_s(:delimited)}"
  end

  def age_display
    return "Not specified" unless age

    "#{age} years old"
  end

  def registration_time_ago
    "Joined #{time_ago_in_words(created_at)} ago"
  end

  def profile_completion_percentage
    return 0 unless profile

    total_fields = 6 # first_name, last_name, bio, website, location, avatar_url
    filled_fields = [
      profile.first_name,
      profile.last_name,
      profile.bio,
      profile.website,
      profile.location,
      profile.avatar_url
    ].count(&:present?)

    (filled_fields.to_f / total_fields * 100).round
  end

  def role_names
    roles.pluck(:name).join(", ")
  end

  private

  def time_ago_in_words(time)
    # Simple implementation - in real app would use Rails helpers
    days = (Time.current - time) / 1.day
    case days
    when 0..1
      "today"
    when 1..7
      "#{days.to_i} days"
    when 7..30
      "#{(days / 7).to_i} weeks"
    else
      "#{(days / 30).to_i} months"
    end
  end
end
