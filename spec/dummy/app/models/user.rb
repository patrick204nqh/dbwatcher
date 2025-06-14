# frozen_string_literal: true

class User < ApplicationRecord
  include Statisticsable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  accepts_nested_attributes_for :posts, :profile

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :with_posts, -> { joins(:posts).distinct }
  scope :admins, -> { joins(:roles).where(roles: { name: "Admin" }) }

  def full_name
    return name unless profile&.first_name && profile.last_name

    "#{profile.first_name} #{profile.last_name}"
  end

  def admin?
    roles.exists?(name: "Admin")
  end

  def toggle_status!
    update!(active: !active)
  end
end
