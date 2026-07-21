module MobileCareProfileAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_mobile_user!
  end

  private

  def authenticate_mobile_user!
    token = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
    payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256").first
    @current_user = User.find_by(id: payload["sub"])
    raise JWT::DecodeError unless @current_user && payload["type"] == "access"
  rescue JWT::DecodeError
    render json: { error: "Your session has expired. Please sign in again." }, status: :unauthorized
  end

  def current_mobile_user
    @current_user
  end

  def current_mobile_care_profile
    return @current_mobile_care_profile if defined?(@current_mobile_care_profile)

    requested_id = request.headers["X-Care-Profile-Id"].presence || params[:care_profile_id]
    @current_mobile_care_profile = if requested_id.present?
      @current_user.active_care_profile_links.find_by(care_profile_id: requested_id)&.care_profile
    else
      @current_user.owned_care_profiles.first || @current_user.active_care_profile_links.first&.care_profile
    end
    render json: { error: "Choose a care profile you can access." }, status: :not_found unless @current_mobile_care_profile
    @current_mobile_care_profile
  end

  def authorize_mobile_care_profile!(permission, capability = :view, emergency: false)
    profile = current_mobile_care_profile
    return false unless profile

    CareProfileAuthorization.new(@current_user, profile).authorize!(permission, capability, emergency: emergency)
    true
  rescue CareProfileAuthorization::NotAuthorized => error
    render json: { error: error.message }, status: :forbidden
    false
  end
end
