module AdminSessionAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :admin_session_active?, :current_admin_user
  end

  private

  def current_admin_user
    @current_admin_user ||= User.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
  end

  def admin_session_active?
    current_admin_user.present?
  end

  def require_admin_authentication
    return if current_admin_user

    redirect_to new_admin_session_path, alert: "Sign in to the admin workspace to continue."
  end

  def require_admin_access!
    return if current_admin_user&.can_access_admin_panel?

    clear_admin_session!
    redirect_to new_admin_session_path, alert: "This account does not have admin access."
  end

  def clear_admin_session!
    session.delete(:admin_user_id)
    session.delete(:pending_admin_identifier)
  end
end
