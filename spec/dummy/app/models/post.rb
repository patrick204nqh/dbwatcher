# frozen_string_literal: true

class Post < ApplicationRecord
  include Statisticsable

  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :attachments, as: :attachable, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true

  enum :status, { draft: 0, published: 1, archived: 2 }

  accepts_nested_attributes_for :comments

  scope :recent, -> { order(created_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :by_author, ->(user) { where(user: user) }
  scope :with_tags, -> { joins(:tags).distinct }

  def published?
    status == "published"
  end

  def can_be_published?
    draft?
  end

  def reading_time
    return 0 if content.blank?

    # Assume 200 words per minute reading speed
    word_count = content.split.size
    (word_count / 200.0).ceil
  end

  def increment_views!
    increment!(:views_count)
  end
end
