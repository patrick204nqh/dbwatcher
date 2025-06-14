# frozen_string_literal: true

# Concern for models that track statistics
module Statisticsable
  extend ActiveSupport::Concern

  class_methods do
    def recent(timeframe = 1.day.ago)
      where(created_at: timeframe..)
    end

    def count_by_status(status_column = :status)
      group(status_column).count
    end

    def count_by_date(date_column = :created_at, period = :day)
      group_by_period(period, date_column).count
    end
  end

  def age_in_days
    return 0 unless created_at

    (Time.current - created_at) / 1.day
  end

  def recent?(timeframe = 1.day.ago)
    created_at >= timeframe
  end
end
