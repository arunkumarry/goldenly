class Api::V1::CareProfileLocationPreferencesController < ActionController::API
  include MobileCareProfileAuthentication

  def show
    return render json: { error: "Choose the active care profile before updating preferences." }, status: :forbidden unless profile_matches_route?
    return unless authorize_mobile_care_profile!(:location_access, :view)

    render json: payload
  end

  def update
    return render json: { error: "Choose the active care profile before updating preferences." }, status: :forbidden unless profile_matches_route?
    return unless authorize_mobile_care_profile!(:location_access, :manage)

    preference = current_mobile_care_profile.location_preference || current_mobile_care_profile.build_location_preference
    attributes = params.permit(:location_sharing_preference, :preferred_hospital_place_id)
    attributes[:preferred_hospital_selected_at] = Time.current if attributes.key?(:preferred_hospital_place_id)
    preference.update!(attributes)
    AuditTrail.record!(action: "care_profile.location_preference_updated", actor: current_mobile_user, care_profile: current_mobile_care_profile, metadata: { preferred_hospital_selected: preference.preferred_hospital_place_id.present? })
    render json: payload
  end

  private

  def payload
    preference = current_mobile_care_profile.location_preference
    { location_preference: { location_sharing_preference: preference&.location_sharing_preference || "ask_each_time", preferred_hospital_place_id: preference&.preferred_hospital_place_id, preferred_hospital_selected_at: preference&.preferred_hospital_selected_at } }
  end

  def profile_matches_route?
    current_mobile_care_profile.id == params[:care_profile_id].to_i
  end
end
