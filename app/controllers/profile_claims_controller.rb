class ProfileClaimsController < ApplicationController
  skip_before_action :require_authentication
  before_action :load_invitation

  def show
    @care_profile = @invitation.care_profile
    @access_links = @care_profile.care_profile_links.active.includes(:user)
  end

  def request_code
    identifier = normalised_identifier
    ensure_invited_identifier!(identifier)
    OneTimeVerification.send_code(identifier)
    session[:pending_profile_claim] = { "invitation_id" => @invitation.id, "identifier" => identifier }
    redirect_to claim_profile_path(@token), notice: "We sent a verification code to #{identifier}."
  rescue AuthenticationIdentifier::InvalidIdentifier, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError, ProfileClaim::ClaimError => error
    redirect_to claim_profile_path(@token), alert: error.message
  end

  def create
    identifier = pending_claim_identifier
    raise ProfileClaim::ClaimError, "Start the claim again from your invitation." unless identifier
    ensure_invited_identifier!(identifier)
    raise ProfileClaim::ClaimError, "That verification code is invalid or has expired." unless OneTimeVerification.approved?(identifier, params.require(:code))

    user = AuthenticationIdentifier.find_user(identifier) || create_account_user(identifier)
    user.update!(verified_at: Time.current) if user.verified_at.nil?
    care_profile = ProfileClaim.new(invitation: @invitation, account_user: user, retain_existing_access: params[:retain_existing_access], source: "web_claim").claim!
    session.delete(:pending_profile_claim)
    session[:user_id] = user.id
    session[:care_profile_id] = care_profile.id
    redirect_to root_path, notice: "Your Goldenly care profile is now active."
  rescue ActiveRecord::RecordInvalid, AuthenticationIdentifier::InvalidIdentifier, ProfileClaim::ClaimError => error
    @care_profile = @invitation.care_profile
    @access_links = @care_profile.care_profile_links.active.includes(:user)
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_content
  end

  private

  def load_invitation
    @token = params.require(:token)
    @invitation = ProfileInvitationIssuer.find_active(@token)
    raise ActiveRecord::RecordNotFound unless @invitation
  end

  def normalised_identifier
    AuthenticationIdentifier.normalize(params.require(:identifier))
  end

  def pending_claim_identifier
    pending = session[:pending_profile_claim]
    pending && pending["invitation_id"] == @invitation.id ? pending["identifier"] : nil
  end

  def ensure_invited_identifier!(identifier)
    return if ActiveSupport::SecurityUtils.secure_compare(ProfileInvitationIssuer.digest(identifier), ProfileInvitationIssuer.digest(@invitation.contact_identifier))

    raise ProfileClaim::ClaimError, "Use the phone number or email address that received this invitation."
  end

  def create_account_user(identifier)
    user = User.new(full_name: @invitation.care_profile.full_name, country: @invitation.care_profile.country, location: @invitation.care_profile.location)
    AuthenticationIdentifier.assign(user, identifier)
    user.save!
    user
  end
end
