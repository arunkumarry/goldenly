class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create verify confirm]

  def new; end

  def create
    identifier = AuthenticationIdentifier.normalize(params[:identifier])
    user = AuthenticationIdentifier.find_user(identifier)
    unless user
      flash.now[:alert] = "No account was found. Create an account first."
      return render :new, status: :unprocessable_content
    end

    OneTimeVerification.send_code(identifier)
    session[:pending_login_identifier] = identifier
    redirect_to verify_session_path, notice: "We sent a verification code to #{identifier}."
  rescue AuthenticationIdentifier::InvalidIdentifier, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end

  def verify
    redirect_to new_session_path unless pending_identifier
  end

  def confirm
    identifier = pending_identifier
    return redirect_to new_session_path, alert: "Start sign in again." unless identifier

    if OneTimeVerification.approved?(identifier, params[:code])
      user = AuthenticationIdentifier.find_user(identifier)
      session.delete(:pending_login_identifier)
      session[:user_id] = user.id
      session[:care_profile_id] = user.owned_care_profiles.first&.id || user.active_care_profile_links.first&.care_profile_id
      AuditTrail.record!(action: "account_user.signed_in", actor: user, metadata: { source: "web" })
      redirect_to root_path, notice: "Welcome back, #{user.full_name}!"
    else
      flash.now[:alert] = "That verification code is invalid or has expired."
      render :verify, status: :unprocessable_content
    end
  rescue EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    flash.now[:alert] = error.message
    render :verify, status: :unprocessable_content
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "You’ve been signed out."
  end

  private

  def pending_identifier
    session[:pending_login_identifier]
  end
end
