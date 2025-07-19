# frozen_string_literal: true

class UserSkill < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  validates :proficiency_level, inclusion: { in: %w[beginner intermediate advanced expert] }
  validates :user_id, uniqueness: { scope: :skill_id }
end
