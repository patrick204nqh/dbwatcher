# frozen_string_literal: true

# Query object for finding users with complex criteria
class UserSearchQuery < ApplicationQuery
  def initialize(search_config, relation = nil)
    @search_config = search_config
    super(relation)
  end

  def call
    query = base_relation.includes(:profile, :roles)

    query = apply_text_search(query) if search_config.query?
    query = apply_filters(query) if search_config.filters?
    apply_ordering(query)
  end

  private

  attr_reader :search_config

  def default_relation
    User.all
  end

  def apply_text_search(query)
    search_term = "%#{search_config.query}%"

    query.where(
      "users.name ILIKE ? OR users.email ILIKE ? OR profiles.first_name ILIKE ? OR profiles.last_name ILIKE ?",
      search_term, search_term, search_term, search_term
    ).left_joins(:profile)
  end

  def apply_filters(query)
    search_config.filters.reduce(query) do |q, (key, value)|
      apply_single_filter(q, key, value)
    end
  end

  def apply_single_filter(query, key, value)
    case key.to_sym
    when :active
      apply_active_filter(query, value)
    when :role
      apply_role_filter(query, value)
    when :age_min
      apply_age_min_filter(query, value)
    when :age_max
      apply_age_max_filter(query, value)
    when :created_after
      apply_created_after_filter(query, value)
    else
      query
    end
  end

  def apply_active_filter(query, value)
    query.where(active: value)
  end

  def apply_role_filter(query, value)
    query.joins(:roles).where(roles: { name: value })
  end

  def apply_age_min_filter(query, value)
    value.present? ? query.where("age >= ?", value.to_i) : query
  end

  def apply_age_max_filter(query, value)
    value.present? ? query.where("age <= ?", value.to_i) : query
  end

  def apply_created_after_filter(query, value)
    value.present? ? query.where("created_at >= ?", Date.parse(value)) : query
  end

  def apply_ordering(query)
    query.order(search_config.ordering)
  end
end
