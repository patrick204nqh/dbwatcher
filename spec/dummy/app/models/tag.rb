# frozen_string_literal: true

class Tag < ApplicationRecord
  include Sluggable
  include Statisticsable

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  validates :name, presence: true, uniqueness: true

  scope :popular, -> { joins(:posts).group("tags.id").order("COUNT(posts.id) DESC") }
  scope :unused, -> { left_joins(:posts).where(posts: { id: nil }) }
end
