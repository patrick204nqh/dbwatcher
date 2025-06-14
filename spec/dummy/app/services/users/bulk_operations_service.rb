# frozen_string_literal: true

module Users
  # Service for handling bulk operations on users
  class BulkOperationsService < ApplicationService
    def initialize(operation:, user_ids: [], params: {})
      super()
      @operation = operation
      @user_ids = Array(user_ids)
      @params = params
    end

    def call
      return failure("No users selected") if user_ids.empty?

      case operation
      when :update
        perform_bulk_update
      when :delete
        perform_bulk_delete
      else
        failure("Unknown operation: #{operation}")
      end
    end

    private

    attr_reader :operation, :user_ids, :params

    def perform_bulk_update
      updated_count = User.where(id: user_ids).update_all(
        active: params[:active] == "true",
        updated_at: Time.current
      )

      success(
        { updated_count: updated_count },
        "Updated #{updated_count} users"
      )
    end

    def perform_bulk_delete
      users_to_delete = User.where(id: user_ids)
      deleted_count = users_to_delete.count
      users_to_delete.destroy_all

      success(
        { deleted_count: deleted_count },
        "Deleted #{deleted_count} users and their associated records"
      )
    end
  end
end
