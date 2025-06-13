# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Simple homepage for the dummy app
  def index
    render plain: "Dummy Rails App - Test Environment for DBWatcher"
  end

  # Database statistics endpoint for testing and monitoring
  def stats
    @stats = build_statistics

    respond_to do |format|
      format.json { render json: @stats }
      format.html { render plain: @stats.to_yaml }
    end
  end

  private

  # Build comprehensive database statistics
  def build_statistics
    {
      users: user_statistics,
      posts: post_statistics,
      comments: comment_statistics,
      tags: Tag.count,
      roles: Role.count,
      last_updated: Time.current
    }
  end

  def user_statistics
    {
      total: User.count,
      active: User.where(active: true).count,
      recent: User.where(created_at: 1.day.ago..).count
    }
  end

  def post_statistics
    {
      total: Post.count,
      published: Post.where(status: :published).count,
      featured: Post.where(featured: true).count,
      recent: Post.where(created_at: 1.day.ago..).count
    }
  end

  def comment_statistics
    {
      total: Comment.count,
      approved: Comment.where(approved: true).count,
      recent: Comment.where(created_at: 1.day.ago..).count
    }
  end
end
