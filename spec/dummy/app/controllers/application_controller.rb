# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Statisticsable
  include DatabaseResettable

  # Temporarily disable CSRF protection for testing
  skip_before_action :verify_authenticity_token

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Database statistics endpoint for testing and monitoring
  def stats
    respond_to do |format|
      format.json { render_statistics(format: :json) }
      format.html { render_statistics(format: :html) }
    end
  end
end
