# frozen_string_literal: true

class User < ApplicationRecord
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
end
