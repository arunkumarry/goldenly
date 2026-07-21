class Api::V1::AuthenticationController < ActionController::API
  rescue_from AuthenticationIdentifier::InvalidIdentifier, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, with: :render_bad_request
  rescue_from Twilio::REST::RestError, with: :render_bad_request

  def request_code
    identifier = AuthenticationIdentifier.normalize(params.require(:identifier))
    OneTimeVerification.send_code(identifier)
    render json: { identifier: identifier, channel: OneTimeVerification.channel_for(identifier), message: "Verification code sent." }, status: :accepted
  end

  def sign_in
    identifier = AuthenticationIdentifier.normalize(params.require(:identifier))
    user = AuthenticationIdentifier.find_user(identifier)
    return render json: { error: "No account was found." }, status: :not_found unless user
    return render json: { error: "Invalid or expired verification code." }, status: :unprocessable_content unless OneTimeVerification.approved?(identifier, params.require(:code))

    AuditTrail.record!(action: "account_user.signed_in", actor: user, metadata: { source: "mobile" })
    render json: { user: user_payload(user), care_profiles: care_profiles_payload(user), active_care_profile_id: user.owned_care_profiles.first&.id || user.active_care_profile_links.first&.care_profile_id, tokens: MobileTokenIssuer.new(user).issue }
  end

  def sign_up
    identifier = AuthenticationIdentifier.normalize(params.require(:identifier))
    return render json: { error: "An account already exists for that email or phone number." }, status: :unprocessable_content if AuthenticationIdentifier.find_user(identifier)
    return render json: { error: "Invalid or expired verification code." }, status: :unprocessable_content unless OneTimeVerification.approved?(identifier, params.require(:code))

    user = nil
    User.transaction do
      user = User.new(user_params)
      AuthenticationIdentifier.assign(user, identifier)
      user.verified_at = Time.current
      user.save!
      onboarding = CareProfileOnboarding.new(account_user: user, source: "mobile")
      care_profile = if params[:setup_for] == "someone_else"
        onboarding.create_for_someone_else!(care_profile_params, relationship: params[:relationship_to_person].presence || "family", consent_basis: params[:consent_basis].presence || "coordinator confirmed initial setup", state: params[:state].presence_in(%w[unclaimed assisted]) || "unclaimed")
      else
        onboarding.create_self!(care_profile_params)
      end
    end
    render json: { user: user_payload(user), care_profiles: care_profiles_payload(user), active_care_profile_id: care_profile.id, tokens: MobileTokenIssuer.new(user).issue }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content
  end

  def refresh
    tokens = MobileTokenIssuer.refresh(params.require(:refresh_token))
    return render json: { error: "Refresh token is invalid or expired." }, status: :unauthorized unless tokens

    render json: { tokens: tokens }
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id)
  end

  def care_profile_params
    (params[:care_profile] || params.require(:member)).permit(:full_name, :phone_number, :preferred_language, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id)
  end

  def user_payload(user)
    user.slice(:id, :full_name, :email_address, :phone_number, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id, :verified_at)
  end

  def care_profiles_payload(user)
    user.active_care_profile_links.map do |link|
      link.care_profile.slice(:id, :full_name, :preferred_language, :state, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id).merge("relationship_to_person" => link.relationship_to_person, "permissions" => link.permissions)
    end
  end

  def render_bad_request(error)
    render json: { error: error.message }, status: :unprocessable_content
  end
end
