class CareProfileLocationPreferencesController < ApplicationController
  before_action :set_care_profile
  before_action -> { require_care_profile_permission!(:location_access, :manage) }, only: :update

  def show
    require_care_profile_permission!(:location_access, :view)
    render json: preference_payload
  end

  def update
    preference = @care_profile.location_preference || @care_profile.build_location_preference
    preference.update!(preference_params)
    AuditTrail.record!(action: "care_profile.location_preference_updated", actor: current_user, care_profile: @care_profile, metadata: { preferred_hospital_selected: preference.preferred_hospital_place_id.present? })
    respond_to do |format|
      format.html { redirect_to nearby_hospitals_path, notice: "Hospital preference saved." }
      format.json { render json: preference_payload, status: :ok }
    end
  end

  private

  def set_care_profile
    @care_profile = params[:care_profile_id] ? current_user.active_care_profile_links.find_by!(care_profile_id: params[:care_profile_id]).care_profile : current_care_profile
  end

  def preference_params
    attributes = params.fetch(:care_profile_location_preference, params).permit(:location_sharing_preference, :preferred_hospital_place_id)
    attributes[:preferred_hospital_selected_at] = Time.current if attributes.key?(:preferred_hospital_place_id)
    attributes
  end

  def preference_payload
    preference = @care_profile.location_preference
    { location_preference: { location_sharing_preference: preference&.location_sharing_preference || "ask_each_time", preferred_hospital_place_id: preference&.preferred_hospital_place_id, preferred_hospital_selected_at: preference&.preferred_hospital_selected_at } }
  end
end
