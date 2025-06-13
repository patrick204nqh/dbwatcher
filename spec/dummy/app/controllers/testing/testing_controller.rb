# frozen_string_literal: true

module Testing
  class TestingController < ApplicationController
    # Complex transaction with multiple models and relationships
    def complex_transaction
      result = create_user_with_transaction
      redirect_to users_path, notice: "Complex transaction completed! Created user #{result[:user_id]} with profile and posts."
    end

    # Mass updates across multiple tables
    def mass_updates
      perform_mass_updates
      redirect_to users_path, notice: "Mass updates completed! Updated multiple records across tables."
    end

    # Cascade deletes to test relationship handling
    def cascade_deletes
      result = perform_cascade_delete
      if result[:success]
        redirect_to users_path, notice: result[:message]
      else
        redirect_to users_path, alert: result[:message]
      end
    end

    # Create with nested associations using accepts_nested_attributes
    def create_with_associations
      user = create_nested_user
      redirect_to user_path(user), notice: "Nested creation completed! Created user with profile and posts."
    end

    # Trigger intentional errors for testing error handling
    def trigger_errors
      errors = simulate_errors
      redirect_to users_path, notice: "Error scenarios tested. Caught #{errors.length} errors as expected."
    end

    # Complex nested operations
    def nested_operations
      post = perform_nested_operations
      redirect_to post_path(post), notice: "Nested operations completed! Created admin user, post, and processed recent comments."
    end

    # Bulk operations with different patterns
    def bulk_operations
      result = perform_bulk_operations
      redirect_to tags_path, notice: "Bulk operations completed! Created tags, updated logins, deleted #{result[:deleted_count]} old posts."
    end

    # Simulate concurrent updates (for testing race conditions)
    def concurrent_updates
      perform_concurrent_updates
      redirect_to users_path, notice: "Concurrent updates simulation completed!"
    end

    # Quick test for rapid iterations
    def quick_test
      stats = calculate_quick_stats
      render json: stats
    end

    # Reset all test data to default state
    def reset_data
      reset_database
      redirect_to users_path, notice: "🔄 Database reset successful! All data refreshed to default state."
    end

    private

    def create_user_with_transaction
      result = nil
      ActiveRecord::Base.transaction do
        user = create_test_user
        profile = create_user_profile(user)
        assign_user_role(user)
        create_user_posts(user)
        result = { user_id: user.id, profile_id: profile.id }
      end
      result
    end

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

        # Add tags and comments
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

    def perform_mass_updates
      update_user_login_counts
      update_comment_approval
      update_post_view_counts
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
      Post.where(status: :published).update_all("views_count = views_count + #{rand(10..100)}")
    end

    def perform_cascade_delete
      user = find_user_with_associations

      return failure_result("No user with associated data found for cascade delete test.") unless user

      user_data = extract_user_data(user)
      user.destroy

      success_result(user_data)
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

    def success_result(user_data)
      {
        success: true,
        message: "Cascade delete completed! Deleted user '#{user_data[:name]}' with #{user_data[:posts_count]} posts and #{user_data[:comments_count]} comments."
      }
    end

    def failure_result(message)
      { success: false, message: message }
    end

    def create_nested_user
      user_params = build_nested_user_params
      user = User.create!(user_params)

      assign_tags_to_user_posts(user)
      user
    end

    def assign_tags_to_user_posts(user)
      user.posts.each do |post|
        post.tags = Tag.limit(2).order("RANDOM()")
      end
    end

    def build_nested_user_params
      {
        name: "Nested User #{Time.current.to_i}",
        email: "nested_#{Time.current.to_i}@example.com",
        age: rand(22..45),
        active: true,
        profile_attributes: build_profile_attributes,
        posts_attributes: build_posts_attributes
      }
    end

    def build_profile_attributes
      {
        first_name: "Nested",
        last_name: "User",
        bio: "Created with nested attributes",
        location: "Nested City"
      }
    end

    def build_posts_attributes
      [
        build_first_post_attributes,
        build_second_post_attributes
      ]
    end

    def build_first_post_attributes
      {
        title: "Nested Post 1",
        content: "Content created via nested attributes. " * 30,
        excerpt: "First nested post",
        status: :published,
        published_at: Time.current,
        comments_attributes: build_first_post_comments
      }
    end

    def build_second_post_attributes
      {
        title: "Nested Post 2",
        content: "Second post via nested attributes. " * 25,
        excerpt: "Second nested post",
        status: :draft
      }
    end

    def build_first_post_comments
      [
        { content: "Nested comment 1", approved: true },
        { content: "Nested comment 2", approved: false }
      ]
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

    def perform_nested_operations
      ActiveRecord::Base.transaction do
        admin = find_or_create_admin_user
        assign_admin_role(admin)
        post = create_admin_announcement(admin)
        process_recent_comments
        post
      end
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

    def perform_bulk_operations
      create_bulk_tags
      update_user_logins
      deleted_count = delete_old_posts

      { deleted_count: deleted_count }
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

    def perform_concurrent_updates
      user = User.first
      return unless user

      simulate_concurrent_updates(user)
    end

    def simulate_concurrent_updates(user)
      5.times do |i|
        user.update!(notes: "Concurrent update #{i + 1} at #{Time.current}")
        sleep(0.1) # Small delay to simulate timing
      end
    end

    def calculate_quick_stats
      {
        users: User.count,
        posts: Post.count,
        comments: Comment.count,
        tags: Tag.count,
        recent_activity: Post.where(created_at: 1.hour.ago..).count
      }
    end

    def reset_database
      clear_all_data
      reseed_database
    end

    def clear_all_data
      [Comment, PostTag, Post, Profile, UserRole, User, Tag, Role].each(&:destroy_all)
    end

    def reseed_database
      load Rails.root.join("db", "seeds.rb")
    end
  end
end
