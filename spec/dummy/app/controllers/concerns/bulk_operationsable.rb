# frozen_string_literal: true

# Concern for controllers that handle bulk operations
module BulkOperationsable
  extend ActiveSupport::Concern

  private

  def perform_bulk_operation(operation, user_ids, params = {})
    result = Users::BulkOperationsService.call(
      operation: operation,
      user_ids: user_ids,
      params: params
    )

    if result.success?
      redirect_to users_path, notice: result.message
    else
      redirect_to users_path, alert: result.message
    end
  end
end
