# frozen_string_literal: true

# Concern for models that need sluggification
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_save :generate_slug, if: :needs_slug?
    validates :slug, uniqueness: true, allow_blank: true
  end

  private

  def needs_slug?
    slug.blank? || slug_source_changed?
  end

  def generate_slug
    self.slug = create_slug_from_source
  end

  def create_slug_from_source
    source = send(slug_source_attribute)
    return if source.blank?

    base_slug = source.downcase.gsub(/\s+/, "-").gsub(/[^\w-]/, "")
    ensure_unique_slug(base_slug)
  end

  def ensure_unique_slug(base_slug)
    slug_candidate = base_slug
    counter = 1

    while self.class.where.not(id: id).exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug_candidate
  end

  def slug_source_changed?
    send("#{slug_source_attribute}_changed?")
  end

  def slug_source_attribute
    :name # Override in including models if different
  end
end
