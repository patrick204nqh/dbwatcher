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
      high_volume_inserts
      high_volume_updates
      high_volume_deletes
      mixed_high_volume_operations
      batch_processing
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
      update_user_skills_experience
      update_category_relationships
      update_skill_proficiency_levels

      success(nil, "Mass updates completed! Updated multiple records across tables including relationships")
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

    def perform_high_volume_inserts
      insert_counts = {}

      ActiveRecord::Base.transaction do
        # Create many users (reduced from 50 to 10)
        insert_counts[:users] = create_many_users(10)

        # Create many posts for existing users (reduced from 100 to 20)
        insert_counts[:posts] = create_many_posts(20)

        # Create many comments (reduced from 200 to 30)
        insert_counts[:comments] = create_many_comments(30)

        # Create many tags (reduced from 30 to 10)
        insert_counts[:tags] = create_many_tags(10)

        # Create many user roles (reduced from 25 to 8)
        insert_counts[:user_roles] = create_many_user_roles(8)

        # Create many user skills (has_many_through relationships)
        insert_counts[:user_skills] = create_many_user_skills(15)

        # Create many category-user relationships (HABTM)
        insert_counts[:category_users] = create_many_category_users(12)

        # Create many attachments (polymorphic)
        insert_counts[:attachments] = create_many_attachments(20)
      end

      total_inserts = insert_counts.values.sum
      success(
        insert_counts,
        "High-volume inserts completed! Created #{total_inserts} records: #{insert_counts.map { |k, v| "#{v} #{k}" }.join(", ")}"
      )
    end

    def perform_high_volume_updates
      update_counts = {}

      # Update many users in batches
      update_counts[:users] = batch_update_users

      # Update many posts
      update_counts[:posts] = batch_update_posts

      # Update many comments
      update_counts[:comments] = batch_update_comments

      # Update profiles
      update_counts[:profiles] = batch_update_profiles

      # Update user skills (has_many_through)
      update_counts[:user_skills] = batch_update_user_skills

      # Update category relationships (HABTM)
      update_counts[:category_relationships] = batch_update_category_relationships

      # Update attachments (polymorphic)
      update_counts[:attachments] = batch_update_attachments

      total_updates = update_counts.values.sum
      success(
        update_counts,
        "High-volume updates completed! Updated #{total_updates} records: #{update_counts.map { |k, v| "#{v} #{k}" }.join(", ")}"
      )
    end

    def perform_high_volume_deletes
      delete_counts = {}

      # Delete many old comments
      delete_counts[:comments] = delete_old_comments

      # Delete many draft posts
      delete_counts[:posts] = delete_many_draft_posts

      # Delete inactive users and their associations
      delete_counts[:users] = delete_inactive_users

      # Delete unused tags
      delete_counts[:tags] = delete_unused_tags

      total_deletes = delete_counts.values.sum
      success(
        delete_counts,
        "High-volume deletes completed! Deleted #{total_deletes} records: #{delete_counts.map { |k, v| "#{v} #{k}" }.join(", ")}"
      )
    end

    def perform_mixed_high_volume_operations
      operation_counts = { inserts: {}, updates: {}, deletes: {} }

      # Phase 1: Create new records with specific characteristics for testing
      ActiveRecord::Base.transaction do
        # Create users with mix of active/inactive for update testing
        operation_counts[:inserts][:users] = create_updatable_users(5)

        # Create posts with mix of published/draft for update testing
        operation_counts[:inserts][:posts] = create_updatable_posts(10)

        # Create comments with mix of approved/unapproved for update testing
        operation_counts[:inserts][:comments] = create_updatable_comments(15)

        # Create some old data for deletion testing (after we have users)
        operation_counts[:inserts][:old_comments] = create_old_test_comments(5)
        operation_counts[:inserts][:old_draft_posts] = create_old_draft_posts(3)
      end

      # Phase 2: Update operations (separate from inserts so DBWatcher tracks them distinctly)
      operation_counts[:updates][:users] = batch_update_users
      operation_counts[:updates][:posts] = batch_update_posts
      operation_counts[:updates][:comments] = batch_update_comments

      # Phase 3: Delete operations (separate so DBWatcher tracks them distinctly)
      operation_counts[:deletes][:comments] = delete_old_comments
      operation_counts[:deletes][:posts] = delete_many_draft_posts

      total_operations = operation_counts.values.map(&:values).flatten.sum
      success(
        operation_counts,
        "Mixed high-volume operations completed! Performed #{total_operations} total operations: #{operation_counts.map { |phase, counts| "#{phase.capitalize}: #{counts.values.sum}" }.join(", ")}"
      )
    end

    def perform_batch_processing
      batch_results = {}

      # Process users in batches of 10
      batch_results[:user_batches] = process_users_in_batches(10)

      # Process posts in batches of 15
      batch_results[:post_batches] = process_posts_in_batches(15)

      # Process comments in batches of 20
      batch_results[:comment_batches] = process_comments_in_batches(20)

      total_batches = batch_results.values.sum
      success(
        batch_results,
        "Batch processing completed! Processed #{total_batches} batches across multiple tables"
      )
    end

    # Helper methods for operations
    def create_test_user
      user = User.create!(
        name: "Transaction User #{Time.current.to_i}",
        email: "transaction_#{Time.current.to_i}@example.com",
        age: rand(25..65),
        active: true,
        salary: rand(50_000..120_000),
        birth_date: rand(30.years).seconds.ago.to_date,
        preferences: { created_in: "transaction", test: true }.to_json,
        notes: "Created via complex transaction test"
      )

      # Add HABTM categories
      categories = Category.limit(3).order("RANDOM()")
      user.categories = categories if categories.any?

      # Add has_many_through skills
      skills = Skill.limit(4).order("RANDOM()")
      skills.each do |skill|
        UserSkill.create!(
          user: user,
          skill: skill,
          proficiency_level: %w[beginner intermediate advanced].sample,
          years_experience: rand(0..10)
        )
      end

      user
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
      User.find_each do |user|
        user.update!(last_login_count: user.last_login_count + 1)
      end
    end

    def update_comment_approval
      Comment.where(approved: false, created_at: 1.day.ago..).find_each do |comment|
        comment.update!(
          approved: true,
          updated_at: Time.current
        )
      end
    end

    def update_post_view_counts
      increment_value = rand(10..100)
      Post.where(status: :published).find_each do |post|
        post.update!(views_count: post.views_count + increment_value)
      end
    end

    def find_user_with_associations
      User.joins(:posts, :comments)
          .includes(:profile, :user_roles, :categories, :skills, :user_skills, :attachments, :uploaded_attachments)
          .first
    end

    def extract_user_data(user)
      {
        name: user.name,
        posts_count: user.posts.count,
        comments_count: user.comments.count,
        categories_count: user.categories.count,
        skills_count: user.skills.count,
        attachments_count: user.attachments.count,
        uploaded_attachments_count: user.uploaded_attachments.count
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
      recent_comments.find_each do |comment|
        comment.update!(approved: true)
      end
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
      User.find_each do |user|
        user.update!(last_login_count: user.last_login_count + 1)
      end
    end

    def delete_old_posts
      Post.where(created_at: ..6.months.ago, status: :draft).find_each(&:destroy!)
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

    # Helper methods for high-volume operations
    def create_many_users(count)
      created_count = 0

      count.times do |i|
        User.create!(
          name: "Bulk User #{i + 1}",
          email: "bulk_user_#{i + 1}_#{Time.current.to_i}@example.com",
          age: rand(18..80),
          active: [true, false].sample,
          salary: rand(30_000..150_000),
          birth_date: rand(60.years).seconds.ago.to_date,
          preferences: { bulk_created: true, batch_id: Time.current.to_i }.to_json,
          notes: "Created via high-volume insert test"
        )
        created_count += 1
      end

      created_count
    end

    def create_many_posts(count)
      users = User.limit(10).pluck(:id)
      return 0 if users.empty?

      created_count = 0
      count.times do |i|
        Post.create!(
          user_id: users.sample,
          title: "Bulk Post #{i + 1} - Sample Title #{rand(1000)}",
          content: "This is bulk content for post #{i + 1}. " * 10,
          excerpt: "Excerpt for bulk post #{i + 1}",
          status: %i[draft published].sample,
          published_at: rand > 0.5 ? Time.current : nil,
          featured: rand > 0.8,
          views_count: rand(0..1000)
        )
        created_count += 1
      end

      created_count
    end

    def create_many_comments(count)
      posts = Post.limit(20).pluck(:id)
      users = User.limit(10).pluck(:id)
      return 0 if posts.empty? || users.empty?

      created_count = 0
      count.times do |i|
        Comment.create!(
          post_id: posts.sample,
          user_id: users.sample,
          content: "Bulk comment #{i + 1}: This is a sample comment for testing purposes.",
          approved: [true, false].sample
        )
        created_count += 1
      end

      created_count
    end

    def create_many_tags(count)
      existing_tags = Tag.pluck(:name)
      tag_names = []

      count.times do |i|
        tag_name = "BulkTag#{i + 1}"
        tag_names << tag_name unless existing_tags.include?(tag_name)
      end

      return 0 if tag_names.empty?

      tags_data = tag_names.map do |name|
        {
          name: name,
          description: "Auto-generated tag: #{name}",
          color: sample_color,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      Tag.insert_all(tags_data)
      tag_names.length
    end

    def create_many_user_roles(count)
      users = User.limit(count).pluck(:id)
      roles = Role.pluck(:id)
      return 0 if users.empty? || roles.empty?

      user_roles_data = []
      users.each do |user_id|
        role_id = roles.sample
        user_roles_data << {
          user_id: user_id,
          role_id: role_id,
          assigned_at: Time.current,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Use insert_all with on_duplicate to avoid duplicate key errors
      begin
        UserRole.insert_all(user_roles_data, record_timestamps: true)
        user_roles_data.length
      rescue ActiveRecord::RecordNotUnique
        # Handle duplicate entries gracefully
        user_roles_data.length / 2 # Approximate successful inserts
      end
    end

    def batch_update_users
      users = User.where(active: true).limit(10)
      updated_count = 0
      users.find_each do |user|
        user.update!(
          last_login_count: user.last_login_count + rand(1..10),
          updated_at: Time.current
        )
        updated_count += 1
      end
      updated_count
    end

    def batch_update_posts
      posts = Post.where(status: :published).limit(8)
      updated_count = 0
      posts.find_each do |post|
        post.update!(
          views_count: post.views_count + rand(10..500),
          updated_at: Time.current
        )
        updated_count += 1
      end
      updated_count
    end

    def batch_update_comments
      comments = Comment.where(approved: false).limit(12)
      updated_count = 0
      comments.find_each do |comment|
        comment.update!(
          approved: true,
          updated_at: Time.current
        )
        updated_count += 1
      end
      updated_count
    end

    def batch_update_profiles
      profiles = Profile.limit(5)
      updated_count = 0
      profiles.find_each do |profile|
        profile.update!(updated_at: Time.current)
        updated_count += 1
      end
      updated_count
    end

    def batch_update_user_skills
      user_skills = UserSkill.limit(8)
      updated_count = 0
      user_skills.find_each do |user_skill|
        user_skill.update!(
          years_experience: [user_skill.years_experience + 1, 20].min,
          updated_at: Time.current
        )
        updated_count += 1
      end
      updated_count
    end

    def batch_update_category_relationships
      # Add categories to users with fewer than 4 categories
      users_needing_categories = User.joins(:categories)
                                     .group("users.id")
                                     .having("COUNT(categories.id) < 4")
                                     .limit(3)

      updated_count = 0
      users_needing_categories.each do |user|
        available_category = Category.where.not(id: user.category_ids).first
        if available_category
          user.categories << available_category
          updated_count += 1
        end
      end
      updated_count
    end

    def batch_update_attachments
      attachments = Attachment.limit(5)
      updated_count = 0
      attachments.find_each do |attachment|
        attachment.update!(
          file_size: [attachment.file_size + rand(1000..10_000), 10_000_000].min,
          metadata: if attachment.metadata.present?
                      JSON.parse(attachment.metadata).merge(last_accessed: Time.current).to_json
                    else
                      { last_accessed: Time.current }.to_json
                    end,
          updated_at: Time.current
        )
        updated_count += 1
      end
      updated_count
    end

    def delete_old_comments
      comments = Comment.where(created_at: ..30.days.ago, approved: false)
      deleted_count = 0
      comments.find_each do |comment|
        comment.destroy!
        deleted_count += 1
      end
      deleted_count
    end

    def delete_many_draft_posts
      posts = Post.where(status: :draft, created_at: ..7.days.ago)
      deleted_count = 0
      posts.find_each do |post|
        post.destroy!
        deleted_count += 1
      end
      deleted_count
    end

    def delete_inactive_users
      users = User.where(active: false, created_at: ..90.days.ago)
      deleted_count = 0
      users.find_each do |user|
        user.destroy!
        deleted_count += 1
      end
      deleted_count
    end

    def delete_unused_tags
      # Delete tags that aren't associated with any posts
      unused_tags = Tag.left_joins(:posts).where(posts: { id: nil })
      deleted_count = 0
      unused_tags.find_each do |tag|
        tag.destroy!
        deleted_count += 1
      end
      deleted_count
    end

    def process_users_in_batches(batch_size)
      batch_count = 0
      User.in_batches(of: batch_size) do |batch|
        batch.update_all(updated_at: Time.current)
        batch_count += 1
      end
      batch_count
    end

    def process_posts_in_batches(batch_size)
      batch_count = 0
      Post.in_batches(of: batch_size) do |batch|
        batch.update_all(views_count: "views_count + 1")
        batch_count += 1
      end
      batch_count
    end

    def process_comments_in_batches(batch_size)
      batch_count = 0
      Comment.in_batches(of: batch_size) do |batch|
        batch.where(approved: false).update_all(approved: true)
        batch_count += 1
      end
      batch_count
    end

    # Helper methods for creating old test data that can be deleted
    def create_old_test_comments(count)
      posts = Post.limit(5).pluck(:id)
      users = User.limit(3).pluck(:id)
      return 0 if posts.empty? || users.empty?

      created_count = 0
      count.times do |i|
        Comment.create!(
          post_id: posts.sample,
          user_id: users.sample,
          content: "Old comment #{i + 1} for deletion testing",
          approved: false,
          created_at: 35.days.ago, # Older than 30 days
          updated_at: 35.days.ago
        )
        created_count += 1
      end

      created_count
    end

    def create_old_draft_posts(count)
      users = User.limit(3).pluck(:id)
      return 0 if users.empty?

      created_count = 0
      count.times do |i|
        Post.create!(
          user_id: users.sample,
          title: "Old Draft Post #{i + 1}",
          content: "Old draft content for deletion testing",
          excerpt: "Old draft excerpt",
          status: :draft,
          created_at: 10.days.ago, # Older than 7 days
          updated_at: 10.days.ago
        )
        created_count += 1
      end

      created_count
    end

    # Helper methods for creating updatable test data
    def create_updatable_users(count)
      created_count = 0

      count.times do |i|
        User.create!(
          name: "Updatable User #{i + 1}",
          email: "updatable_user_#{i + 1}_#{Time.current.to_i}@example.com",
          age: rand(18..80),
          active: i.even?, # Mix of active/inactive for update testing
          salary: rand(30_000..150_000),
          birth_date: rand(60.years).seconds.ago.to_date,
          preferences: { updatable: true, batch_id: Time.current.to_i }.to_json,
          notes: "Created for update testing",
          last_login_count: 0 # Set to 0 so update can increment
        )
        created_count += 1
      end

      created_count
    end

    def create_updatable_posts(count)
      users = User.limit(10).pluck(:id)
      return 0 if users.empty?

      created_count = 0
      count.times do |i|
        Post.create!(
          user_id: users.sample,
          title: "Updatable Post #{i + 1} - Sample Title #{rand(1000)}",
          content: "This is updatable content for post #{i + 1}. " * 10,
          excerpt: "Updatable excerpt for post #{i + 1}",
          status: i < 5 ? :published : :draft, # Mix of published/draft for update testing
          published_at: i < 5 ? Time.current : nil,
          featured: false,
          views_count: 0 # Set to 0 so update can increment
        )
        created_count += 1
      end

      created_count
    end

    def create_updatable_comments(count)
      posts = Post.limit(20).pluck(:id)
      users = User.limit(10).pluck(:id)
      return 0 if posts.empty? || users.empty?

      created_count = 0
      count.times do |i|
        Comment.create!(
          post_id: posts.sample,
          user_id: users.sample,
          content: "Updatable comment #{i + 1}: This comment can be updated for testing purposes.",
          approved: i.even? # Mix of approved/unapproved for update testing
        )
        created_count += 1
      end

      created_count
    end

    # New methods for handling HABTM and has_many_through relationships
    def update_user_skills_experience
      UserSkill.limit(10).find_each do |user_skill|
        user_skill.update!(years_experience: user_skill.years_experience + 1)
      end
    end

    def update_category_relationships
      # Add new categories to users who have fewer than 3
      User.joins(:categories)
          .group("users.id")
          .having("COUNT(categories.id) < 3")
          .limit(5)
          .each do |user|
            available_categories = Category.where.not(id: user.category_ids).limit(2)
            user.categories.concat(available_categories) if available_categories.any?
          end
    end

    def update_skill_proficiency_levels
      # Upgrade beginner skills to intermediate
      UserSkill.where(proficiency_level: "beginner").limit(5).find_each do |user_skill|
        user_skill.update!(proficiency_level: "intermediate")
      end
    end

    def create_many_user_skills(count)
      users = User.limit(count / 2).pluck(:id)
      skills = Skill.limit(count / 3).pluck(:id)
      return 0 if users.empty? || skills.empty?

      created_count = 0
      count.times do
        user_id = users.sample
        skill_id = skills.sample

        # Skip if combination already exists
        next if UserSkill.exists?(user_id: user_id, skill_id: skill_id)

        UserSkill.create!(
          user_id: user_id,
          skill_id: skill_id,
          proficiency_level: %w[beginner intermediate advanced expert].sample,
          years_experience: rand(0..15)
        )
        created_count += 1
      end

      created_count
    end

    def create_many_category_users(count)
      users = User.limit(count / 2).pluck(:id)
      categories = Category.pluck(:id)
      return 0 if users.empty? || categories.empty?

      created_count = 0
      count.times do
        user = User.find(users.sample)
        category = Category.find(categories.sample)

        # Skip if relationship already exists
        next if user.categories.include?(category)

        user.categories << category
        created_count += 1
      end

      created_count
    end

    def create_many_attachments(count)
      # Get various attachable entities
      users = User.limit(count / 4).pluck(:id)
      posts = Post.limit(count / 4).pluck(:id)
      profiles = Profile.limit(count / 4).pluck(:id)
      comments = Comment.limit(count / 4).pluck(:id)

      return 0 if users.empty?

      created_count = 0
      attachable_data = [
        { type: "User", ids: users },
        { type: "Post", ids: posts },
        { type: "Profile", ids: profiles },
        { type: "Comment", ids: comments }
      ].reject { |data| data[:ids].empty? }

      count.times do |i|
        attachable = attachable_data.sample

        Attachment.create!(
          attachable_type: attachable[:type],
          attachable_id: attachable[:ids].sample,
          user_id: users.sample,
          filename: "bulk_attachment_#{i + 1}.#{%w[jpg png pdf docx mp3 mp4].sample}",
          content_type: ["image/jpeg", "image/png", "application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "audio/mp3", "video/mp4"].sample,
          file_size: rand(1024..5_000_000),
          attachment_type: %w[image document video audio].sample,
          url: "https://cdn.example.com/bulk/attachment_#{i + 1}",
          metadata: {
            bulk_created: true,
            batch_id: Time.current.to_i,
            attachable_type: attachable[:type],
            created_by: "bulk_operations"
          }.to_json
        )
        created_count += 1
      rescue ActiveRecord::RecordInvalid
        # Skip invalid records
        next
      end

      created_count
    end
  end
end
