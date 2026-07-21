class ProfileInvitationsController < ApplicationController
  before_action -> { require_care_profile_permission!(:trusted_circle, :manage) }

  def create
    care_profile = selected_care_profile
    invitation, token = CareProfileAccessManager.new(actor: current_user, care_profile: care_profile).invite!(
      identifier: invitation_params.fetch(:contact_identifier),
      delivery_channel: invitation_params.fetch(:delivery_channel),
      invitation_kind: "claim",
      permissions: {}
    )
    claim_url = claim_profile_url(token: token)
    delivery = ProfileInvitationDelivery.new(invitation: invitation, token: token, claim_url: claim_url).deliver!
    session[:care_profile_id] = care_profile.id
    notice = delivery == :email_sent ? "Invitation emailed to #{invitation.contact_identifier}." : "Invitation created for #{care_profile.full_name}. Copy this secure link to deliver it: #{claim_url}"
    redirect_to trusted_circle_path, notice: notice
  rescue ActiveRecord::RecordInvalid, CareProfileAccessManager::AccessError, AuthenticationIdentifier::InvalidIdentifier, ProfileInvitationDelivery::DeliveryError => error
    redirect_to trusted_circle_path, alert: error.message
  end

  def destroy
    invitation = current_care_profile.profile_invitations.find(params[:id])
    invitation.update!(cancelled_at: Time.current)
    AuditTrail.record!(action: "profile_invitation.cancelled", actor: current_user, care_profile: current_care_profile, metadata: { invitation_id: invitation.id })
    redirect_to trusted_circle_path, notice: "Invitation cancelled."
  end

  private

  def invitation_params
    params.require(:profile_invitation).permit(:care_profile_id, :contact_identifier, :delivery_channel)
  end

  def selected_care_profile
    link = current_user.active_care_profile_links.find_by!(care_profile_id: invitation_params.fetch(:care_profile_id))
    care_profile = link.care_profile
    CareProfileAuthorization.new(current_user, care_profile).authorize!(:trusted_circle, :manage)
    care_profile
  end
end
