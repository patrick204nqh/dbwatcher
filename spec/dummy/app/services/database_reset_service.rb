# frozen_string_literal: true

# Service for resetting database to clean state
class DatabaseResetService < ApplicationService
  def call
    ActiveRecord::Base.transaction do
      clear_all_data
      # Don't reseed - leave database completely empty
    end

    success(nil, "Database completely reset! All data truncated to empty state.")
  rescue StandardError => e
    failure("Database reset failed: #{e.message}")
  end

  private

  def clear_all_data
    # Clear in dependency order to avoid foreign key constraints
    # Use delete_all for faster truncation instead of destroy_all
    [Comment, PostTag, Post, Profile, UserRole, User, Tag, Role].each(&:delete_all)

    # Reset auto-increment counters
    reset_sequences
  end

  def reset_sequences
    # Reset auto-increment sequences to start from 1
    # Handle different database adapters
    case ActiveRecord::Base.connection.adapter_name.downcase
    when "postgresql"
      tables = %w[users profiles roles user_roles tags posts comments post_tags]
      tables.each do |table|
        ActiveRecord::Base.connection.reset_pk_sequence!(table)
      end
    when "sqlite"
      # SQLite handles auto-increment automatically when table is empty
      ActiveRecord::Base.connection.execute("UPDATE sqlite_sequence SET seq = 0 WHERE name IN ('users', 'profiles', 'roles', 'user_roles', 'tags', 'posts', 'comments', 'post_tags')")
    when "mysql2"
      tables = %w[users profiles roles user_roles tags posts comments post_tags]
      tables.each do |table|
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} AUTO_INCREMENT = 1")
      end
    end
  rescue => e
    Rails.logger.warn "Could not reset sequences: #{e.message}"
  end
end
