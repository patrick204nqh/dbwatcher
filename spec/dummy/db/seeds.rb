# frozen_string_literal: true

puts "🌱 Seeding test data for DBWatcher testing..."

# Clear existing data in dependency order (most dependent first)
ActiveRecord::Base.connection.execute("DELETE FROM attachments")
[Comment, PostTag, UserSkill, Post, Profile, UserRole, User, Tag, Role, Category, Skill].each(&:destroy_all)

puts "🗑️  Cleared existing data"

# Create roles
puts "👥 Creating roles..."
admin_role = Role.create!(
  name: "Admin",
  description: "Full access to all features",
  permissions: { can_edit: true, can_delete: true, can_publish: true }.to_json
)
editor_role = Role.create!(
  name: "Editor",
  description: "Can edit and publish posts",
  permissions: { can_edit: true, can_delete: false, can_publish: true }.to_json
)
user_role = Role.create!(
  name: "User",
  description: "Basic user access",
  permissions: { can_edit: false, can_delete: false, can_publish: false }.to_json
)

# Create categories
puts "📂 Creating categories..."
categories = %w[Technology Business Design Health Education Travel Sports Music Art Finance].map do |name|
  Category.create!(
    name: name,
    description: "Category for #{name} related content and user interests"
  )
end

# Create skills
puts "💡 Creating skills..."
skills = [
  "Ruby", "Rails", "JavaScript", "React", "Node.js", "Python", "Java", "SQL",
  "Docker", "AWS", "Git", "MongoDB", "PostgreSQL", "Redis", "GraphQL",
  "Vue.js", "Angular", "TypeScript", "Go", "Kubernetes"
].map do |name|
  Skill.create!(
    name: name,
    description: "Professional skill in #{name}"
  )
end

# Create tags
puts "🏷️  Creating tags..."
tags = %w[Ruby Rails Programming Technology Web-Development Database Testing API Frontend Backend].map do |name|
  Tag.create!(
    name: name,
    slug: name.downcase.gsub(/[^a-z0-9]+/, "-"),
    color: ["#red", "#blue", "#green", "#purple", "#orange", "#pink", "#yellow", "#indigo"].sample,
    description: "Posts related to #{name}"
  )
end

# Create users with profiles
puts "👤 Creating users with profiles..."
users = []
15.times do |i|
  user = User.create!(
    name: "User #{i + 1}",
    email: "user#{i + 1}@example.com",
    age: rand(18..65),
    active: [true, true, true, false].sample, # 75% active
    salary: rand(30_000..150_000),
    birth_date: rand(30.years).seconds.ago.to_date,
    last_login_at: rand(1.week).seconds.ago,
    preferences: {
      theme: %w[dark light].sample,
      notifications: [true, false].sample,
      language: %w[en es fr].sample,
      timezone: %w[UTC EST PST].sample
    }.to_json,
    notes: "Generated user for testing DBWatcher. User #{i + 1} has various attributes for comprehensive testing."
  )

  Profile.create!(
    user: user,
    first_name: "FirstName#{i + 1}",
    last_name: "LastName#{i + 1}",
    bio: "I'm user #{i + 1}, a #{%w[developer designer manager analyst tester].sample} who loves #{%w[coding reading gaming traveling music].sample}.",
    website: "https://user#{i + 1}.example.com",
    location: ["New York", "San Francisco", "London", "Tokyo", "Berlin", "Sydney", "Toronto"].sample,
    avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=user#{i + 1}"
  )

  # Assign random roles (users can have multiple roles)
  [admin_role, editor_role, user_role].sample(rand(1..2)).each do |role|
    UserRole.create!(
      user: user,
      role: role,
      assigned_at: rand(1.month).seconds.ago
    )
  end

  # Assign random categories (HABTM relationship)
  user.categories = categories.sample(rand(2..5))

  # Assign random skills (has_many_through relationship)
  skills.sample(rand(3..8)).each do |skill|
    UserSkill.create!(
      user: user,
      skill: skill,
      proficiency_level: %w[beginner intermediate advanced expert].sample,
      years_experience: rand(0..15)
    )
  end

  # Add profile avatar attachment
  if [true, false, false].sample # 33% chance
    user.attachments.create!(
      user: user,
      filename: "avatar_user_#{user.id}.jpg",
      content_type: "image/jpeg",
      file_size: rand(50_000..500_000),
      attachment_type: "image",
      url: "https://cdn.example.com/avatars/user_#{user.id}.jpg",
      metadata: {
        alt_text: "Profile picture for #{user.name}",
        is_avatar: true,
        dimensions: { width: 400, height: 400 }
      }.to_json
    )
  end

  # Add profile attachments (resume, portfolio, etc.)
  if [true, false].sample
    user.profile.attachments.create!(
      user: user,
      filename: "resume_#{user.name.gsub(" ", "_").downcase}.pdf",
      content_type: "application/pdf",
      file_size: rand(100_000..2_000_000),
      attachment_type: "document",
      url: "https://cdn.example.com/resumes/#{user.id}/resume.pdf",
      metadata: {
        document_type: "resume",
        pages: rand(1..5),
        last_updated: Time.current
      }.to_json
    )
  end

  users << user
end

# Create posts with realistic content
puts "📝 Creating posts..."
posts = []
users.each do |user|
  post_count = case user.roles.pluck(:name)
               when ["Admin"] then rand(3..8)
               when ["Editor"] then rand(2..6)
               else rand(0..3)
               end

  post_count.times do |_i|
    status = case user.roles.pluck(:name).join(",")
             when /Admin|Editor/ then %i[draft published archived].sample
             else %i[draft published].sample
             end

    published_time = status == :published ? rand(2.months).seconds.ago : nil

    post = Post.create!(
      user: user,
      title: "#{["How to", "Understanding", "A Guide to", "Introduction to", "Advanced"].sample} #{["Rails Development", "Database Design", "API Architecture", "Frontend Frameworks", "Testing Strategies", "Performance Optimization"].sample}",
      content: ("This is a comprehensive post about the topic. " * rand(20..100)) +
               "\n\nIt covers many important aspects and provides valuable insights for developers. " \
               "The content is generated for testing purposes but aims to be realistic.",
      excerpt: "A brief summary of this post covering key concepts and insights.",
      status: status,
      views_count: status == :published ? rand(0..2000) : 0,
      featured: [true, false, false, false].sample, # 25% featured
      published_at: published_time
    )

    # Add random tags to posts
    post.tags = tags.sample(rand(2..5))

    # Add attachments to some posts
    if [true, false].sample # 50% chance
      attachment_count = rand(1..3)
      attachment_count.times do |attach_idx|
        post.attachments.create!(
          user: user,
          filename: "post_#{post.id}_attachment_#{attach_idx + 1}.#{%w[jpg png pdf docx mp4].sample}",
          content_type: ["image/jpeg", "image/png", "application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "video/mp4"].sample,
          file_size: rand(1024..5_000_000),
          attachment_type: %w[image document video].sample,
          url: "https://cdn.example.com/attachments/post_#{post.id}_#{attach_idx + 1}",
          metadata: {
            alt_text: "Post attachment #{attach_idx + 1}",
            description: "Sample attachment for post #{post.title}",
            uploaded_at: Time.current
          }.to_json
        )
      end
    end

    posts << post
  end
end

# Create comments (including nested comments)
puts "💬 Creating comments..."
published_posts = posts.select { |p| p.status == "published" }
published_posts.each do |post|
  # Create top-level comments
  comment_count = rand(0..8)
  comment_count.times do
    commenter = users.sample
    comment = Comment.create!(
      user: commenter,
      post: post,
      content: [
        "This is a great post! Really helped me understand the concepts.",
        "Thanks for sharing this insight. Very useful information.",
        "I have a different perspective on this topic...",
        "Could you elaborate more on the second point?",
        "Excellent explanation, bookmarking this for later reference.",
        "I disagree with some points but overall good content.",
        "This solved my exact problem, thank you!",
        "Looking forward to more posts like this."
      ].sample + " (Comment from #{commenter.name})",
      approved: [true, true, true, false].sample # 75% approved
    )

    # Add attachment to some comments
    if [true, false, false, false].sample # 25% chance
      comment.attachments.create!(
        user: commenter,
        filename: "comment_screenshot_#{comment.id}.png",
        content_type: "image/png",
        file_size: rand(100_000..1_000_000),
        attachment_type: "image",
        url: "https://cdn.example.com/comments/#{comment.id}/screenshot.png",
        metadata: {
          alt_text: "Screenshot attached to comment",
          comment_id: comment.id,
          is_screenshot: true
        }.to_json
      )
    end

    # Add some replies to comments
    next unless [true, false].sample # 50% chance of replies

    reply_count = rand(1..3)
    reply_count.times do
      replier = users.sample
      Comment.create!(
        user: replier,
        post: post,
        parent: comment,
        content: [
          "I agree with your point!",
          "Thanks for the clarification.",
          "That's an interesting perspective.",
          "Could you provide more details?",
          "I think there's another way to look at this."
        ].sample + " (Reply from #{replier.name})",
        approved: [true, true, false].sample # 66% approved
      )
    end
  end
end

# Add some recent activity for testing real-time scenarios
puts "⚡ Adding recent activity..."
recent_users = users.sample(5)
recent_users.each do |user|
  # Recent login
  user.update!(last_login_at: rand(1.hour).seconds.ago)

  # Recent post if they have permission
  next unless user.roles.any? { |role| %w[Admin Editor].include?(role.name) }

  Post.create!(
    user: user,
    title: "Recent Activity: #{Time.current.strftime("%B %d")} Update",
    content: "This is a recent post created for testing real-time database activity tracking.",
    excerpt: "Recent activity post for testing",
    status: :published,
    published_at: rand(30.minutes).seconds.ago
  )
end

puts "✅ Seed data created successfully!"
puts
puts "📊 Database Summary:"
puts "Users: #{User.count} (#{User.where(active: true).count} active)"
puts "Profiles: #{Profile.count}"
puts "Posts: #{Post.count} (#{Post.where(status: "published").count} published)"
puts "Comments: #{Comment.count} (#{Comment.where(approved: true).count} approved)"
puts "Tags: #{Tag.count}"
puts "Roles: #{Role.count}"
puts "User Roles: #{UserRole.count}"
puts "Categories: #{Category.count}"
puts "Skills: #{Skill.count}"
puts "User Skills: #{UserSkill.count}"
puts "Attachments: #{Attachment.count}"
puts
puts "🔗 Relationship Summary:"
puts "HABTM (Users ↔ Categories): #{User.joins(:categories).count} connections"
puts "Has Many Through (Users ↔ Skills): #{UserSkill.count} connections"
puts "Polymorphic (Attachments): #{Attachment.count} total attachments"
puts "Users with multiple skills: #{User.joins(:skills).group("users.id").having("COUNT(skills.id) > 1").count.size}"
puts "Users with multiple categories: #{User.joins(:categories).group("users.id").having("COUNT(categories.id) > 1").count.size}"
puts
puts "📎 Attachment Summary:"
puts "Post attachments: #{Attachment.where(attachable_type: "Post").count}"
puts "User attachments: #{Attachment.where(attachable_type: "User").count}"
puts "Profile attachments: #{Attachment.where(attachable_type: "Profile").count}"
puts "Comment attachments: #{Attachment.where(attachable_type: "Comment").count}"
puts "Images: #{Attachment.where(attachment_type: "image").count}"
puts "Documents: #{Attachment.where(attachment_type: "document").count}"
puts "Videos: #{Attachment.where(attachment_type: "video").count}"
puts
puts "🎯 Ready for DBWatcher testing!"
puts "🔗 Visit your Rails app and add ?dbwatch=true to any URL to start tracking"
