# frozen_string_literal: true

# Concern for controllers that need database reset functionality
module DatabaseResettable
  extend ActiveSupport::Concern

  private

  def reset_database
    DatabaseResetService.call
    redirect_to users_path, notice: "🔄 Database reset successful! All data refreshed to default state."
  end
end
