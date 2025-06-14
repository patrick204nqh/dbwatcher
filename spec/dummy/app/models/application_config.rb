# frozen_string_literal: true

# Configuration object for the dummy app
class ApplicationConfig
  include Singleton

  def initialize
    @settings = {
      pagination: {
        default_page_size: ApplicationConstants::DEFAULT_PAGE_SIZE,
        max_page_size: ApplicationConstants::MAX_PAGE_SIZE
      },
      user: {
        min_age: ApplicationConstants::MIN_USER_AGE,
        max_age: ApplicationConstants::MAX_USER_AGE,
        default_role: ApplicationConstants::DEFAULT_USER_ROLE
      },
      content: {
        max_bio_length: ApplicationConstants::MAX_BIO_LENGTH,
        reading_words_per_minute: ApplicationConstants::READING_WORDS_PER_MINUTE
      },
      bulk_operations: {
        max_size: ApplicationConstants::MAX_BULK_OPERATION_SIZE
      }
    }
  end

  def get(path)
    keys = path.split(".")
    keys.reduce(@settings) { |hash, key| hash&.[](key.to_sym) }
  end

  def set(path, value)
    keys = path.split(".")
    last_key = keys.pop.to_sym
    hash = keys.reduce(@settings) { |h, key| h&.[](key.to_sym) }
    hash[last_key] = value if hash
  end

  # Convenience methods
  def pagination
    @settings[:pagination]
  end

  def user_settings
    @settings[:user]
  end

  def content_settings
    @settings[:content]
  end

  def bulk_operation_settings
    @settings[:bulk_operations]
  end

  class << self
    delegate :get, :set, :pagination, :user_settings, :content_settings, :bulk_operation_settings, to: :instance
  end
end
