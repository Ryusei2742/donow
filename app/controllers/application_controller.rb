class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :active_avoidance_rules

  private

  def active_avoidance_rules
    @active_avoidance_rules ||= Current.user.avoidance_rules.active.order(:title)
  end
end
