class Api::V1::CareProfileHospitalsController < ActionController::API
  include MobileCareProfileAuthentication

  def create
    profile = current_mobile_care_profile
    return unless profile
    return render json: { error: "Choose the active care profile before searching." }, status: :forbidden unless profile.id == params[:care_profile_id].to_i

    result = HospitalSearch::Service.new(
      care_profile: profile,
      actor: current_mobile_user,
      location_source: params.fetch(:location_source, "saved_address"),
      location: params[:location],
      radius_meters: params.fetch(:radius_meters, HospitalSearch::Service::DEFAULT_RADIUS_METERS),
      language_code: params.fetch(:language_code, "en"),
      emergency: params[:location_source] == "sos"
    ).call
    render json: result
  rescue HospitalSearch::Service::SearchError => error
    render json: { error: error.message }, status: :unprocessable_content
  end
end
