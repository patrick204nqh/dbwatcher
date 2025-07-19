# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: "parent_id"
  has_many :attachments, as: :attachable, dependent: :destroy

  validates :content, presence: true

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  scope :top_level, -> { where(parent_id: nil) }
end
