# frozen_string_literal: true

module ApplicationConstants
  # Pagination defaults
  DEFAULT_PAGE_SIZE = 50
  MAX_PAGE_SIZE = 100

  # User constants
  MIN_USER_AGE = 13
  MAX_USER_AGE = 150
  DEFAULT_USER_ROLE = "User"

  # Content constants
  MAX_BIO_LENGTH = 500
  READING_WORDS_PER_MINUTE = 200

  # Tag colors
  TAG_COLORS = %w[#blue #green #red #purple #yellow #orange #pink #indigo].freeze

  # Statistics timeframes
  RECENT_TIMEFRAME = 1.day.ago
  ACTIVITY_TIMEFRAME = 1.hour.ago

  # Bulk operation limits
  MAX_BULK_OPERATION_SIZE = 1000

  # File paths
  SEEDS_FILE_PATH = Rails.root.join("db", "seeds.rb")
end
