# frozen_string_literal: true

# Concern for controllers that need statistics
module Statisticsable
  extend ActiveSupport::Concern

  private

  def load_statistics
    @statistics = StatisticsService.call.data
  end

  def render_statistics(format: :json)
    result = StatisticsService.call

    if result.success?
      case format
      when :json
        render json: result.data
      when :html
        render plain: result.data.to_yaml
      end
    else
      render json: { error: "Failed to load statistics" }, status: :internal_server_error
    end
  end
end
