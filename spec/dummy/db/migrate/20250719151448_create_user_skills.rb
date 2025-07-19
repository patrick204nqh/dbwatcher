# frozen_string_literal: true

class CreateUserSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :user_skills do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.string :proficiency_level
      t.integer :years_experience

      t.timestamps
    end
  end
end
