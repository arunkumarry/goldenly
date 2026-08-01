class NearbyHospitalsController < ApplicationController
  before_action :ensure_care_profile!

  def show
    @care_profile = current_care_profile
    @location_preference = @care_profile.location_preference
    @emergency_number = CountryEmergencyNumber.for(@care_profile.country)
  end

  def create
    @care_profile = current_care_profile
    @location_preference = @care_profile.location_preference
    @emergency_number = CountryEmergencyNumber.for(@care_profile.country)
    search_input = search_input_with_continuation
    @results = HospitalSearch::Service.new(
      care_profile: @care_profile,
      actor: current_user,
      location_source: search_input.fetch(:location_source, "saved_address"),
      location: search_input[:location],
      radius_meters: search_input.fetch(:radius_meters, HospitalSearch::Service::DEFAULT_RADIUS_METERS),
      language_code: language_code
    ).call
    respond_to do |format|
      format.html { render :show }
      format.turbo_stream
    end
  rescue HospitalSearch::Service::SearchError => error
    @search_error = error.message
    respond_to do |format|
      format.html { render :show, status: :unprocessable_content }
      format.turbo_stream { render :create, status: :unprocessable_content }
    end
  end

  private

  def ensure_care_profile!
    redirect_to new_care_profile_path, alert: "Add a care profile before searching for hospitals." unless current_care_profile
  end

  def hospital_search_params
    params.permit(:location_source, :radius_meters, :continuation_token, location: %i[latitude longitude label])
  end

  def search_input_with_continuation
    input = hospital_search_params.to_h.symbolize_keys
    return input unless input[:continuation_token].present?

    continuation = HospitalSearchContinuation.verify(input[:continuation_token])
    raise HospitalSearch::Service::SearchError, "That search location has expired. Choose a location again." unless continuation && continuation["care_profile_id"] == current_care_profile.id

    input.merge(location_source: continuation.fetch("location_source"), location: continuation.fetch("location")).except(:continuation_token)
  end

  def language_code
    current_care_profile.preferred_language.to_s.casecmp?("Telugu") ? "te" : "en"
  end
end
