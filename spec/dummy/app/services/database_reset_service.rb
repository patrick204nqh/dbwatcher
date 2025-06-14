# frozen_string_literal: true

# Service for resetting database to clean state
class DatabaseResetService < ApplicationService
  def call
    ActiveRecord::Base.transaction do
      clear_all_data
      reseed_database
    end

    success(nil, "Database reset completed successfully")
  rescue StandardError => e
    failure("Database reset failed: #{e.message}")
  end

  private

  def clear_all_data
    # Clear in dependency order to avoid foreign key constraints
    [Comment, PostTag, Post, Profile, UserRole, User, Tag, Role].each(&:destroy_all)
  end

  def reseed_database
    load Rails.root.join("db", "seeds.rb")
  end
end
