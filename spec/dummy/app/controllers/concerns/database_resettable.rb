# frozen_string_literal: true

# Concern for controllers that need database reset functionality
module DatabaseResettable
  extend ActiveSupport::Concern

  private

  def reset_database
    result = DatabaseResetService.call
    if result.success?
      redirect_to root_path, notice: "🔄 Database reset successful! All data refreshed to default state."
    else
      redirect_to root_path, alert: "❌ Database reset failed: #{result.message}"
    end
  end
end
