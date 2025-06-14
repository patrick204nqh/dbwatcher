# frozen_string_literal: true

# Value object for pagination configuration
class PaginationConfig
  DEFAULT_LIMIT = 50
  DEFAULT_OFFSET = 0

  attr_reader :limit, :offset, :page

  def initialize(limit: DEFAULT_LIMIT, offset: DEFAULT_OFFSET, page: 1)
    @limit = [limit.to_i, 1].max
    @offset = [offset.to_i, 0].max
    @page = [page.to_i, 1].max
  end

  def self.from_params(params)
    page = params[:page].to_i
    limit = params[:limit].to_i

    # Calculate offset from page if provided
    offset = if page > 1
               (page - 1) * (limit.positive? ? limit : DEFAULT_LIMIT)
             else
               0
             end

    new(
      limit: limit.positive? ? limit : DEFAULT_LIMIT,
      offset: offset,
      page: page.positive? ? page : 1
    )
  end

  def next_page
    page + 1
  end

  def previous_page
    [page - 1, 1].max
  end

  def previous?
    page > 1
  end
end
