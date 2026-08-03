class Api::V1::HospitalSearchActionsController < ActionController::API
  include MobileCareProfileAuthentication

  def create
    event = current_mobile_care_profile.hospital_search_events.find(params[:hospital_search_id])
    return unless authorize_mobile_care_profile!(:location_access, :view)

    action = event.hospital_place_actions.create!(
      google_place_id: params.require(:google_place_id), action_type: params.require(:action_type), initiated_at: Time.current
    )
    AuditTrail.record!(action: "hospital.#{action.action_type}", actor: current_mobile_user, care_profile: current_mobile_care_profile, metadata: { hospital_search_event_id: event.id, google_place_id: action.google_place_id })
    render json: { ok: true }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Hospital search not found." }, status: :not_found
  end
end
