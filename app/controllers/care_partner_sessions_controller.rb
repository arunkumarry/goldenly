class CarePartnerSessionsController < ApplicationController
  skip_before_action :require_authentication

  def new
    redirect_to care_partners_root_path if current_care_partner_user
  end

  def create
    identifier = AuthenticationIdentifier.normalize(params[:identifier])
    user = AuthenticationIdentifier.find_user(identifier)
    capture_new_applicant!(identifier) unless user

    OneTimeVerification.send_code(identifier)
    session[:pending_care_partner_identifier] = identifier
    redirect_to verify_care_partner_session_path, notice: "We sent a verification code to #{identifier}."
  rescue AuthenticationIdentifier::InvalidIdentifier, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError, ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end

  def verify
    redirect_to new_care_partner_session_path unless pending_identifier
  end

  def confirm
    identifier = pending_identifier
    return redirect_to(new_care_partner_session_path, alert: "Start Care Partner sign-in again.") unless identifier

    unless OneTimeVerification.approved?(identifier, params[:code])
      flash.now[:alert] = "That verification code is invalid or has expired."
      return render :verify, status: :unprocessable_content
    end

    user = AuthenticationIdentifier.find_user(identifier) || create_care_partner_user!(identifier)
    user.update!(verified_at: Time.current) if user.verified_at.blank?
    user.care_partner_account || user.create_care_partner_account!
    session.delete(:pending_care_partner_identifier)
    session.delete(:pending_care_partner_signup)
    session[:care_partner_user_id] = user.id
    AuditTrail.record!(action: "care_partner.signed_in", actor: user, metadata: { source: "web" })
    redirect_to care_partners_root_path, notice: "Welcome to your Care Partner workspace."
  rescue EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError, ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.message
    render :verify, status: :unprocessable_content
  end

  def destroy
    session.delete(:care_partner_user_id)
    session.delete(:pending_care_partner_identifier)
    session.delete(:pending_care_partner_signup)
    redirect_to new_care_partner_session_path, notice: "You’ve signed out of the Care Partner workspace. Your member session is unchanged."
  end

  private

  def pending_identifier
    session[:pending_care_partner_identifier]
  end

  def capture_new_applicant!(identifier)
    details = params.permit(:full_name, :country)
    if details[:full_name].blank? || details[:country].blank?
      raise ActiveRecord::RecordInvalid.new(User.new).tap do |error|
        error.record.errors.add(:base, "Enter your full name and country to create a new Care Partner account.")
      end
    end

    session[:pending_care_partner_signup] = details.merge("identifier" => identifier).to_h
  end

  def create_care_partner_user!(identifier)
    attributes = session.fetch(:pending_care_partner_signup, {}).symbolize_keys
    raise ActiveRecord::RecordInvalid, User.new if attributes[:full_name].blank? || attributes[:country].blank?

    user = User.new(full_name: attributes[:full_name], country: attributes[:country], verified_at: Time.current)
    AuthenticationIdentifier.assign(user, identifier)
    user.save!
    user
  end
end
