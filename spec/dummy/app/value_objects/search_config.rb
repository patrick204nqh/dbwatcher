# frozen_string_literal: true

# Value object for search configuration
class SearchConfig
  attr_reader :query, :filters, :sort_by, :sort_direction

  def initialize(query: "", filters: {}, sort_by: :created_at, sort_direction: :desc)
    @query = query.to_s.strip
    @filters = filters.is_a?(Hash) ? filters : {}
    @sort_by = sort_by.to_sym
    @sort_direction = validate_sort_direction(sort_direction)
  end

  def self.from_params(params)
    new(
      query: params[:q],
      filters: extract_filters(params),
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction]
    )
  end

  def query?
    query.present?
  end

  def filters?
    filters.any?
  end

  def ordering
    "#{sort_by} #{sort_direction}"
  end

  private

  def validate_sort_direction(direction)
    %i[asc desc].include?(direction.to_sym) ? direction.to_sym : :desc
  end

  class << self
    private

    def extract_filters(params)
      filter_params = params.select { |key, _| key.to_s.start_with?("filter_") }
      filter_params.transform_keys { |key| key.to_s.gsub("filter_", "").to_sym }
    end
  end
end
