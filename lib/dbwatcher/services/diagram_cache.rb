# frozen_string_literal: true

module Dbwatcher
  module Services
    # Caching layer for diagram generation to improve performance
    #
    # Provides intelligent caching with TTL and session-based invalidation
    # to avoid redundant diagram generation for unchanged data.
    #
    # @example
    #   cache = DiagramCache.new
    #   cache.set("diagram:session123:erd", diagram_content)
    #   result = cache.get("diagram:session123:erd")
    class DiagramCache
      DEFAULT_TTL = 3600 # 1 hour in seconds
      MAX_CACHE_SIZE = 1000

      # Initialize cache with configuration
      #
      # @param config [Hash] cache configuration options
      # @option config [Object] :cache_store Rails cache store instance
      # @option config [String] :namespace cache key namespace
      # @option config [Integer] :default_ttl default time-to-live in seconds
      # @option config [Integer] :max_size maximum cache entries
      # @option config [Logger] :logger logger instance
      def initialize(config = {})
        @config = default_config.merge(config)
        @cache = @config[:cache_store] || Rails.cache
        @logger = @config[:logger] || Rails.logger
      end

      # Get cached value by key
      #
      # @param key [String] cache key
      # @return [Object, nil] cached value or nil if not found
      def get(key)
        cache_key = build_cache_key(key)
        result = @cache.read(cache_key)

        if result
          @logger.debug("Cache hit for key #{cache_key}")
          result
        else
          @logger.debug("Cache miss for key #{cache_key}")
          nil
        end
      rescue StandardError => e
        @logger.warn("Cache read error for key #{cache_key}: #{e.message}")
        nil
      end

      # Set cached value with optional TTL
      #
      # @param key [String] cache key
      # @param value [Object] value to cache
      # @param ttl [Integer, nil] time-to-live in seconds, uses default if nil
      def set(key, value, ttl: nil)
        cache_key = build_cache_key(key)
        ttl ||= @config[:default_ttl]

        @cache.write(cache_key, value, expires_in: ttl)
        @logger.debug("Cache set for key #{cache_key} with TTL #{ttl}")
      rescue StandardError => e
        @logger.warn("Cache write error for key #{cache_key}: #{e.message}")
      end

      # Delete cached value
      #
      # @param key [String] cache key
      def delete(key)
        cache_key = build_cache_key(key)
        @cache.delete(cache_key)
        @logger.debug("Cache delete for key #{cache_key}")
      rescue StandardError => e
        @logger.warn("Cache delete error for key #{cache_key}: #{e.message}")
      end

      # Clear all cached diagrams for a session
      #
      # @param session_id [String] session identifier
      def clear_session_cache(session_id)
        pattern = "diagram:#{session_id}:*"
        @logger.info("Clearing session cache for #{session_id} with pattern #{pattern}")

        # NOTE: Implementation depends on cache store capabilities
        # For Rails.cache (MemoryStore), we'd need to iterate keys
        # For Redis, we could use SCAN with pattern matching
        if @cache.respond_to?(:delete_matched)
          cache_pattern = build_cache_key(pattern)
          @cache.delete_matched(cache_pattern)
        else
          @logger.warn("Cache store doesn't support pattern deletion for pattern #{pattern}")
        end
      rescue StandardError => e
        @logger.error("Error clearing session cache for #{session_id}: #{e.message}")
      end

      # Check if cache is available and responding
      #
      # @return [Boolean] true if cache is healthy
      def healthy?
        test_key = build_cache_key("health_check")
        @cache.write(test_key, "test", expires_in: 1.second)
        @cache.read(test_key) == "test"
      rescue StandardError
        false
      ensure
        begin
          @cache.delete(test_key)
        rescue StandardError
          nil
        end
      end

      private

      # Default cache configuration
      #
      # @return [Hash] default configuration
      def default_config
        {
          namespace: "dbwatcher:diagrams",
          default_ttl: DEFAULT_TTL,
          max_size: MAX_CACHE_SIZE
        }
      end

      # Build namespaced cache key
      #
      # @param key [String] base key
      # @return [String] namespaced cache key
      def build_cache_key(key)
        "#{@config[:namespace]}:#{key}"
      end
    end
  end
end
