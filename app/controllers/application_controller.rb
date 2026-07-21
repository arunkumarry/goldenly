class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_authentication

  helper_method :current_user, :current_member, :navigation_items

  private

  def navigation_items
    [
      [ "Home", root_path, "⌂" ],
      [ "Care timeline", care_timeline_path, "◷" ],
      [ "Care plan", new_reminder_path, "▣" ],
      [ "Services", new_service_request_path, "✦" ],
      [ "Member profile", edit_member_path, "▤" ],
      [ "Add member", new_member_path, "＋" ],
      [ "Trusted circle", trusted_circle_path, "♧" ],
      [ "My profile", edit_profile_path, "◉" ]
    ]
  end

  def current_member
    @current_member ||= current_user.members.find_by(id: session[:member_id]) || current_user.members.first
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_authentication
    return if current_user

    redirect_to new_session_path, alert: "Please sign in to continue."
  end
end
