class UsersController < ApplicationController
  # Signup verification happens before an Account User session exists.
  skip_before_action :require_authentication, only: %i[new create verify confirm]

  def new
    @user = User.new
    @care_profile = CareProfile.new(preferred_language: "English")
  end

  def create
    identifier = AuthenticationIdentifier.normalize(params[:identifier])
    if AuthenticationIdentifier.find_user(identifier)
      flash.now[:alert] = "An account already exists for that email or phone number."
      return render :new, status: :unprocessable_content
    end

    @user = User.new(user_params)
    AuthenticationIdentifier.assign(@user, identifier)
    @care_profile = CareProfile.new(care_profile_params)
    if @user.valid? && @care_profile.valid?
      session[:pending_signup] = { "identifier" => identifier, "user" => user_params.to_h, "care_profile" => care_profile_params.to_h, "setup_for" => params[:setup_for], "relationship_to_person" => params[:relationship_to_person], "consent_basis" => params[:consent_basis] }
      OneTimeVerification.send_code(identifier)
      redirect_to verify_users_path, notice: "We sent a verification code to #{identifier}."
    else
      render :new, status: :unprocessable_content
    end
  rescue AuthenticationIdentifier::InvalidIdentifier, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    @user ||= User.new(user_params)
    @care_profile ||= CareProfile.new(care_profile_params)
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end

  def verify
    redirect_to new_user_path unless pending_signup
  end

  def confirm
    signup = pending_signup
    return redirect_to new_user_path, alert: "Start signup again." unless signup

    unless OneTimeVerification.approved?(signup.fetch("identifier"), params[:code])
      OneTimeVerification.send_code(signup.fetch("identifier"))
      flash.now[:alert] = "That verification code is invalid or has expired. We sent you a new code."
      return render :verify, status: :unprocessable_content
    end

    User.transaction do
      @user = User.new(signup.fetch("user"))
      AuthenticationIdentifier.assign(@user, signup.fetch("identifier"))
      @user.verified_at = Time.current
      @user.save!
      onboarding = CareProfileOnboarding.new(account_user: @user)
      @care_profile = if signup["setup_for"] == "someone_else"
        onboarding.create_for_someone_else!(signup.fetch("care_profile"), relationship: signup["relationship_to_person"].presence || "family", consent_basis: signup["consent_basis"].presence || "coordinator confirmed initial setup")
      else
        onboarding.create_self!(signup.fetch("care_profile"))
      end
    end
    session.delete(:pending_signup)
    session[:user_id] = @user.id
    session[:care_profile_id] = @care_profile.id
    redirect_to dashboard_path, notice: "Welcome to Goldenly, #{@user.full_name}!"
  rescue ActiveRecord::RecordInvalid, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    flash.now[:alert] = error.message
    render :verify, status: :unprocessable_content
  end

  private

  def user_params
    params.require(:user).permit(*place_fields, :full_name)
  end

  def care_profile_params
    params.require(:care_profile).permit(*place_fields, :full_name, :phone_number, :preferred_language)
  end

  def place_fields
    %i[address location city region country country_code postal_code latitude longitude google_place_id]
  end

  def pending_signup
    session[:pending_signup]
  end
end
