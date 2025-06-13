# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :title, presence: true
  validates :content, presence: true

  enum :status, { draft: 0, published: 1, archived: 2 }

  accepts_nested_attributes_for :comments

  scope :recent, -> { order(created_at: :desc) }
  scope :featured, -> { where(featured: true) }
end
