class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_authentication

  helper_method :current_user, :current_care_profile, :current_care_profile_link, :navigation_items, :coordinator_mode?

  private

  def navigation_items
    [
      [ "Home", dashboard_path, "⌂" ],
      [ "Care timeline", care_timeline_path, "◷" ],
      [ "Calendar", calendar_path, "▦" ],
      [ "Care plan", new_reminder_path, "▣" ],
      [ "Services", new_service_request_path, "✦" ],
      [ "Care profile", edit_care_profile_path(current_care_profile), "▤" ],
      [ "Add a person", new_care_profile_path, "＋" ],
      [ "Trusted circle", trusted_circle_path, "♧" ],
      [ "My profile", edit_profile_path, "◉" ]
    ]
  end

  def current_care_profile
    @current_care_profile ||= begin
      selected_link = current_user.active_care_profile_links.find_by(care_profile_id: session[:care_profile_id]) if session[:care_profile_id]
      selected_link&.care_profile || current_user.active_care_profile_links.first&.care_profile
    end
  end

  def current_care_profile_link
    return unless current_care_profile

    @current_care_profile_link ||= current_user.care_profile_link_for(current_care_profile)
  end

  def coordinator_mode?
    current_care_profile && !current_care_profile.owned_by?(current_user)
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_authentication
    return if current_user

    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def require_care_profile_permission!(permission, capability = :view, emergency: false)
    raise ActiveRecord::RecordNotFound unless current_care_profile

    CareProfileAuthorization.new(current_user, current_care_profile).authorize!(permission, capability, emergency: emergency)
  rescue CareProfileAuthorization::NotAuthorized => error
    respond_to do |format|
      format.html { redirect_to dashboard_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :forbidden }
    end
  end
end
