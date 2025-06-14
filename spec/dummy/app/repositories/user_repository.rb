# frozen_string_literal: true

# Repository for User-specific queries
class UserRepository < ApplicationRepository
  def initialize
    super(User)
  end

  def active_users
    where(active: true)
  end

  def inactive_users
    where(active: false)
  end

  def recent_users(timeframe = 1.day.ago)
    where(created_at: timeframe..)
  end

  def with_associations
    includes(:profile, :posts, :roles, :comments)
  end

  def find_with_associations(id)
    with_associations.find(id)
  end

  def paginated(limit: 50, offset: 0)
    with_associations
      .order(created_at: :desc)
      .limit(limit)
      .offset(offset)
  end

  def users_with_posts_and_comments
    joins(:posts, :comments)
      .includes(:profile, :user_roles)
      .distinct
  end

  def bulk_update_active_status(user_ids, active_status)
    where(id: user_ids).update_all(
      active: active_status,
      updated_at: Time.current
    )
  end

  def statistics
    {
      total: count,
      active: active_users.count,
      inactive: inactive_users.count,
      recent: recent_users.count
    }
  end
end
