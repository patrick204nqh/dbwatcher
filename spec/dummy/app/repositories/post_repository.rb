# frozen_string_literal: true

# Repository for Post-specific queries
class PostRepository < ApplicationRepository
  def initialize
    super(Post)
  end

  def published
    where(status: :published)
  end

  def drafts
    where(status: :draft)
  end

  def featured
    where(featured: true)
  end

  def recent(timeframe = 1.day.ago)
    where(created_at: timeframe..)
  end

  def with_associations
    includes(:user, :tags, :comments)
  end

  def paginated(limit: 50, offset: 0)
    with_associations
      .order(created_at: :desc)
      .limit(limit)
      .offset(offset)
  end

  def user_posts(user, limit: 10)
    where(user: user)
      .includes(:tags, :comments)
      .order(created_at: :desc)
      .limit(limit)
  end

  def old_drafts(months_ago = 6)
    where(created_at: ..months_ago.months.ago, status: :draft)
  end

  def increment_views_for_published(increment_value)
    published.update_all(["views_count = views_count + ?", increment_value])
  end

  def statistics
    {
      total: count,
      published: published.count,
      drafts: drafts.count,
      featured: featured.count,
      recent: recent.count
    }
  end
end
