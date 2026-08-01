class HospitalPlaceActionsController < ApplicationController
  def create
    event = current_care_profile.hospital_search_events.find(params[:hospital_search_id])
    require_care_profile_permission!(:location_access, :view)
    action = event.hospital_place_actions.create!(
      google_place_id: params.require(:google_place_id),
      action_type: params.require(:action_type), initiated_at: Time.current
    )
    AuditTrail.record!(action: "hospital.#{action.action_type}", actor: current_user, care_profile: current_care_profile, metadata: { hospital_search_event_id: event.id, google_place_id: action.google_place_id })
    head :no_content
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
