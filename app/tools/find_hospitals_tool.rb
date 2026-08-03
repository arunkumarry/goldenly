class FindHospitalsTool < RubyLLM::Tool
  desc "Find factual nearby hospital listings. Use only for a hospital-location request, never to recommend clinical treatment or emergency capacity."
  param :location_source, type: "string", desc: "Use saved_address only when a saved profile address is available. Use current_location or manual_location only to request the app's location picker; do not invent coordinates."

  def initialize(context:)
    @context = context
  end

  def name = "find_hospitals"

  def execute(location_source: "saved_address")
    unless location_source == "saved_address"
      @context.location_change_requested = true
      return { status: "needs_location_choice", message: "Ask the person to choose current device location, the saved address, or another authorised address in the hospital finder." }
    end

    @context.hospital_search = HospitalSearch::Service.new(
      care_profile: @context.care_profile,
      actor: @context.actor,
      location_source: "saved_address",
      language_code: @context.care_profile.preferred_language.to_s.casecmp?("Telugu") ? "te" : "en"
    ).call
    hospitals = @context.hospital_search.fetch(:hospitals)
    { status: "ok", count: hospitals.count, hospitals: hospitals.map { |hospital| { name: hospital[:name], distance_meters: hospital[:distance_meters], open_status: hospital[:open_status] } }, message: "Present these nearby listings as factual options only. The app will display call and directions controls." }
  rescue HospitalSearch::Service::SearchError => error
    { status: "unavailable", message: error.message }
  end
end
