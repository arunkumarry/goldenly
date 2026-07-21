class CareProfileLinksController < ApplicationController
  before_action -> { require_care_profile_permission!(:trusted_circle, :manage) }

  def update
    link = current_care_profile.care_profile_links.find(params[:id])
    CareProfileAccessManager.new(actor: current_user, care_profile: current_care_profile).update_link!(link: link, permissions: permission_params)
    redirect_to trusted_circle_path, notice: "Access permissions updated."
  rescue CareProfileAccessManager::AccessError, ActiveRecord::RecordInvalid => error
    redirect_to trusted_circle_path, alert: error.message
  end

  def destroy
    link = current_care_profile.care_profile_links.find(params[:id])
    raise CareProfileAccessManager::AccessError, "You cannot remove the profile owner." if link.owner?

    link.update!(status: "revoked")
    AuditTrail.record!(action: "care_profile_link.revoked", actor: current_user, care_profile: current_care_profile, metadata: { link_id: link.id })
    redirect_to trusted_circle_path, notice: "Access removed."
  rescue CareProfileAccessManager::AccessError => error
    redirect_to trusted_circle_path, alert: error.message
  end

  private

  def permission_params
    params.require(:care_profile_link)
      .permit(permissions: CareProfilePermissions::CATALOGUE)
      .fetch(:permissions, {})
      .to_h
      .reject { |_key, value| value == "none" }
  end
end
