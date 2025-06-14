# frozen_string_literal: true

# Service for calculating database statistics
class StatisticsService < ApplicationService
  def call
    success(build_statistics)
  end

  private

  def build_statistics
    {
      users: user_statistics,
      posts: post_statistics,
      comments: comment_statistics,
      tags: tag_statistics,
      roles: role_statistics,
      last_updated: Time.current
    }
  end

  def user_statistics
    {
      total: User.count,
      active: User.where(active: true).count,
      inactive: User.where(active: false).count,
      recent: User.where(created_at: 1.day.ago..).count
    }
  end

  def post_statistics
    {
      total: Post.count,
      published: Post.where(status: :published).count,
      draft: Post.where(status: :draft).count,
      featured: Post.where(featured: true).count,
      recent: Post.where(created_at: 1.day.ago..).count
    }
  end

  def comment_statistics
    {
      total: Comment.count,
      approved: Comment.where(approved: true).count,
      pending: Comment.where(approved: false).count,
      recent: Comment.where(created_at: 1.day.ago..).count
    }
  end

  def tag_statistics
    {
      total: Tag.count,
      used: Tag.joins(:posts).distinct.count
    }
  end

  def role_statistics
    {
      total: Role.count,
      with_users: Role.joins(:users).distinct.count,
      user_assignments: UserRole.count
    }
  end
end
