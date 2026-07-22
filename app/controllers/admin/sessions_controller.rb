class Admin::SessionsController < ApplicationController
  include AdminSessionAuthentication

  skip_before_action :require_authentication

  def new
    redirect_to admin_root_path if current_admin_user&.can_access_admin_panel?
  end

  def create
    identifier = AuthenticationIdentifier.normalize(params[:identifier])
    user = AuthenticationIdentifier.find_user(identifier)
    unless user&.can_access_admin_panel?
      flash.now[:alert] = "This identifier does not have admin access."
      return render :new, status: :unprocessable_content
    end

    OneTimeVerification.send_code(identifier)
    session[:pending_admin_identifier] = identifier
    redirect_to verify_admin_session_path, notice: "We sent a verification code to #{identifier}."
  rescue AuthenticationIdentifier::InvalidIdentifier, EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end

  def verify
    redirect_to new_admin_session_path unless pending_identifier
  end

  def confirm
    identifier = pending_identifier
    return redirect_to(new_admin_session_path, alert: "Start admin sign-in again.") unless identifier

    unless OneTimeVerification.approved?(identifier, params[:code])
      flash.now[:alert] = "That verification code is invalid or has expired."
      return render :verify, status: :unprocessable_content
    end

    user = AuthenticationIdentifier.find_user(identifier)
    unless user&.can_access_admin_panel?
      clear_admin_session!
      return redirect_to(new_admin_session_path, alert: "This account does not have admin access.")
    end

    user.update!(verified_at: Time.current) if user.verified_at.blank?
    session.delete(:pending_admin_identifier)
    session[:admin_user_id] = user.id
    AuditTrail.record!(action: "admin.signed_in", actor: user, metadata: { source: "web" })
    redirect_to admin_root_path, notice: "Welcome to the Goldenly admin workspace."
  rescue EmailOtp::DeliveryError, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    flash.now[:alert] = error.message
    render :verify, status: :unprocessable_content
  end

  def destroy
    user = current_admin_user
    clear_admin_session!
    AuditTrail.record!(action: "admin.signed_out", actor: user, metadata: { source: "web" }) if user
    redirect_to new_admin_session_path, notice: "You have signed out of the admin workspace."
  end

  private

  def pending_identifier
    session[:pending_admin_identifier]
  end
end
