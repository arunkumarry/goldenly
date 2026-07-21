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

    render json: { user: user_payload(user), tokens: MobileTokenIssuer.new(user).issue }
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
      user.members.create!(member_params)
    end
    render json: { user: user_payload(user), tokens: MobileTokenIssuer.new(user).issue }, status: :created
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
    params.require(:user).permit(:full_name, :country, :location)
  end

  def member_params
    params.require(:member).permit(:full_name, :phone_number, :preferred_language, :relationship_to_user, :country, :location)
  end

  def user_payload(user)
    user.slice(:id, :full_name, :email_address, :phone_number, :country, :location, :verified_at)
  end

  def render_bad_request(error)
    render json: { error: error.message }, status: :unprocessable_content
  end
end
