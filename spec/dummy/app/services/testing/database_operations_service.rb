# frozen_string_literal: true

module Testing
  # Service for complex database testing operations
  class DatabaseOperationsService < ApplicationService
    OPERATIONS = %w[
      complex_transaction
      mass_updates
      cascade_deletes
      nested_operations
      bulk_operations
      concurrent_updates
      trigger_errors
    ].freeze

    def initialize(operation:, params: {})
      super()
      @operation = operation.to_s
      @params = params
    end

    def call
      return failure("Unknown operation: #{operation}") unless OPERATIONS.include?(operation)

      send("perform_#{operation}")
    rescue StandardError => e
      failure("Operation failed: #{e.message}", [e.message])
    end

    private

    attr_reader :operation, :params

    def perform_complex_transaction
      result = nil
      ActiveRecord::Base.transaction do
        user = create_test_user
        profile = create_user_profile(user)
        assign_user_role(user)
        create_user_posts(user)
        result = { user_id: user.id, profile_id: profile.id }
      end

      success(result, "Complex transaction completed! Created user #{result[:user_id]} with profile and posts")
    end

    def perform_mass_updates
      update_user_login_counts
      update_comment_approval
      update_post_view_counts

      success(nil, "Mass updates completed! Updated multiple records across tables")
    end

    def perform_cascade_deletes
      user = find_user_with_associations
      return failure("No user with associated data found for cascade delete test") unless user

      user_data = extract_user_data(user)
      user.destroy

      success(
        user_data,
        "Cascade delete completed! Deleted user '#{user_data[:name]}' with #{user_data[:posts_count]} posts and #{user_data[:comments_count]} comments"
      )
    end

    def perform_nested_operations
      post = nil
      ActiveRecord::Base.transaction do
        admin = find_or_create_admin_user
        assign_admin_role(admin)
        post = create_admin_announcement(admin)
        process_recent_comments
      end

      success(post, "Nested operations completed! Created admin user, post, and processed recent comments")
    end

    def perform_bulk_operations
      create_bulk_tags
      update_user_logins
      deleted_count = delete_old_posts

      success(
        { deleted_count: deleted_count },
        "Bulk operations completed! Created tags, updated logins, deleted #{deleted_count} old posts"
      )
    end

    def perform_concurrent_updates
      user = User.first
      return failure("No users available for concurrent updates") unless user

      simulate_concurrent_updates(user)
      success(nil, "Concurrent updates simulation completed!")
    end

    def perform_trigger_errors
      errors = simulate_errors
      success(
        { errors_count: errors.length },
        "Error scenarios tested. Caught #{errors.length} errors as expected"
      )
    end

    # Helper methods for operations
    def create_test_user
      User.create!(
        name: "Transaction User #{Time.current.to_i}",
        email: "transaction_#{Time.current.to_i}@example.com",
        age: rand(25..65),
        active: true,
        salary: rand(50_000..120_000),
        birth_date: rand(30.years).seconds.ago.to_date,
        preferences: { created_in: "transaction", test: true }.to_json,
        notes: "Created via complex transaction test"
      )
    end

    def create_user_profile(user)
      Profile.create!(
        user: user,
        first_name: "Transaction",
        last_name: "User",
        bio: "Profile created in complex transaction",
        website: "https://transaction-test.example.com",
        location: "Test City"
      )
    end

    def assign_user_role(user)
      role = Role.find_by(name: "User") || Role.first
      UserRole.create!(user: user, role: role, assigned_at: Time.current) if role
    end

    def create_user_posts(user)
      3.times do |i|
        post = user.posts.create!(
          title: "Transaction Post #{i + 1}",
          content: "Content created in transaction #{i + 1}. " * 20,
          excerpt: "Transaction excerpt #{i + 1}",
          status: i.zero? ? :published : :draft,
          published_at: i.zero? ? Time.current : nil
        )

        add_tags_to_post(post)
        add_comment_to_post(post, i)
      end
    end

    def add_tags_to_post(post)
      tags = Tag.limit(3).order("RANDOM()")
      post.tags = tags if tags.any?
    end

    def add_comment_to_post(post, index)
      return unless post.published?

      post.comments.create!(
        content: "Self-comment on transaction post #{index + 1}",
        approved: true
      )
    end

    def update_user_login_counts
      User.update_all("last_login_count = last_login_count + 1")
    end

    def update_comment_approval
      Comment.where(approved: false, created_at: 1.day.ago..).update_all(
        approved: true,
        updated_at: Time.current
      )
    end

    def update_post_view_counts
      increment_value = rand(10..100)
      Post.where(status: :published).update_all(["views_count = views_count + ?", increment_value])
    end

    def find_user_with_associations
      User.joins(:posts, :comments).includes(:profile, :user_roles).first
    end

    def extract_user_data(user)
      {
        name: user.name,
        posts_count: user.posts.count,
        comments_count: user.comments.count
      }
    end

    def find_or_create_admin_user
      admin = User.find_or_create_by(email: "admin@test.com") do |u|
        u.name = "Test Admin"
        u.age = 35
        u.active = true
      end

      create_admin_profile(admin) unless admin.profile
      admin
    end

    def create_admin_profile(admin)
      admin.create_profile!(
        first_name: "Test",
        last_name: "Admin",
        bio: "System administrator for testing"
      )
    end

    def assign_admin_role(admin)
      admin_role = find_or_create_admin_role
      admin.user_roles.find_or_create_by(role: admin_role)
    end

    def find_or_create_admin_role
      Role.find_or_create_by(name: "Admin") do |r|
        r.description = "Full system access"
      end
    end

    def create_admin_announcement(admin)
      admin.posts.create!(
        title: "System Announcement - #{Date.current}",
        content: "This is an automated system announcement created during nested operations testing.",
        excerpt: "System announcement",
        status: :published,
        featured: true,
        published_at: Time.current
      )
    end

    def process_recent_comments
      recent_comments = Comment.where(approved: false, created_at: 1.hour.ago..)
      recent_comments.update_all(approved: true)
    end

    def create_bulk_tags
      tag_names = %w[Technology Science Art Music Sports Travel Food Health]
      tag_names.each do |name|
        create_tag_if_needed(name)
      end
    end

    def create_tag_if_needed(name)
      Tag.find_or_create_by(name: name) do |tag|
        tag.description = "Tag for #{name.downcase} related content"
        tag.color = sample_color
      end
    end

    def sample_color
      ["#blue", "#green", "#red", "#purple", "#yellow"].sample
    end

    def update_user_logins
      User.update_all("last_login_count = last_login_count + 1")
    end

    def delete_old_posts
      Post.where(created_at: ..6.months.ago, status: :draft).delete_all
    end

    def simulate_concurrent_updates(user)
      5.times do |i|
        user.update!(notes: "Concurrent update #{i + 1} at #{Time.current}")
        sleep(0.1) # Small delay to simulate timing
      end
    end

    def simulate_errors
      errors = []
      errors << test_validation_errors
      errors << test_duplicate_email_errors
      errors.compact
    end

    def test_validation_errors
      User.create!(name: "", email: "invalid")
      nil
    rescue ActiveRecord::RecordInvalid => e
      { type: "validation", message: e.message }
    end

    def test_duplicate_email_errors
      existing_user = User.first
      return nil unless existing_user

      User.create!(name: "Test", email: existing_user.email)
      nil
    rescue ActiveRecord::RecordInvalid => e
      { type: "duplicate", message: e.message }
    end
  end
end
