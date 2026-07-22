module CarePartnerSessionAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_care_partner_user, :current_care_partner, :care_partner_session_active?
  end

  private

  def current_user
    current_care_partner_user
  end

  def current_care_partner
    @current_care_partner ||= current_care_partner_user&.care_partner
  end

  def care_partner_session_active?
    current_care_partner_user.present?
  end

  def require_care_partner_authentication
    return if current_care_partner_user

    redirect_to new_care_partner_session_path, alert: "Sign in to your Care Partner account to continue."
  end
end
