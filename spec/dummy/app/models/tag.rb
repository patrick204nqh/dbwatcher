# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  validates :name, presence: true, uniqueness: true

  before_save :generate_slug

  private

  def generate_slug
    self.slug = name.downcase.gsub(/\s+/, "-").gsub(/[^\w-]/, "") if name.present?
  end
end
