# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Concerns
      # Provides timestamping capabilities for storage objects
      #
      # This concern adds created_at and updated_at functionality to storage
      # objects, following Rails conventions for timestamp management.
      #
      # @example
      #   class SessionStorage < BaseStorage
      #     include Concerns::Timestampable
      #   end
      module Timestampable
        def self.included(base)
          base.attr_reader :created_at, :updated_at
        end

        # Sets initial timestamps on creation
        #
        # @return [void]
        def initialize_timestamps
          now = current_time
          @created_at = now
          @updated_at = now
        end

        # Updates the updated_at timestamp
        #
        # @return [Time] the new updated_at timestamp
        def touch_updated_at
          @updated_at = current_time
        end

        # Calculates age since creation
        #
        # @return [Float] age in seconds since creation
        def age
          current_time - created_at
        end

        # Checks if the object was recently created
        #
        # @param threshold [Integer] threshold in seconds (default: 1 hour)
        # @return [Boolean] true if created within threshold
        def recently_created?(threshold = 3600)
          age < threshold
        end

        # Checks if the object was recently updated
        #
        # @param threshold [Integer] threshold in seconds (default: 1 hour)
        # @return [Boolean] true if updated within threshold
        def recently_updated?(threshold = 3600)
          (current_time - updated_at) < threshold
        end

        private

        # Returns current time (compatible with and without Rails)
        #
        # @return [Time] current time
        def current_time
          if defined?(Time.current)
            Time.current
          else
            Time.now
          end
        end
      end
    end
  end
end
