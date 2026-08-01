class HospitalSearch::Service
  class SearchError < StandardError; end

  DEFAULT_RADIUS_METERS = 10_000
  MAX_RADIUS_METERS = 20_000

  def initialize(care_profile:, actor:, location_source:, location: nil, radius_meters: DEFAULT_RADIUS_METERS, language_code: "en", emergency: false)
    @care_profile = care_profile
    @actor = actor
    @location_source = location_source.to_s
    @location = location
    @radius_meters = radius_meters.to_i
    @language_code = language_code.to_s.presence || "en"
    @emergency = emergency
  end

  def call
    validate_radius!
    resolved = HospitalSearch::LocationResolver.new(
      care_profile: @care_profile,
      actor: @actor,
      location_source: @location_source,
      location: @location,
      emergency: @emergency
    ).resolve

    places = GooglePlaces.nearby_hospitals(
      latitude: resolved.fetch(:latitude), longitude: resolved.fetch(:longitude),
      radius_meters: @radius_meters, language_code: @language_code
    )
    hospitals = normalise(places, resolved)
    event = record!(resolved, hospitals.count, hospitals.any? ? "completed" : "no_results")

    {
      search_event_id: event.id,
      search_context: {
        care_profile_name: @care_profile.full_name,
        location_source: @location_source,
        location_label: resolved.fetch(:label),
        radius_meters: @radius_meters
      },
      continuation_token: HospitalSearchContinuation.issue(care_profile: @care_profile, location_source: @location_source, location: resolved),
      hospitals: hospitals,
      can_expand_search: hospitals.empty? && @radius_meters < MAX_RADIUS_METERS,
      disclaimer: "Goldenly shows nearby hospital listings. Confirm services and availability directly with the hospital."
    }
  rescue HospitalSearch::LocationResolver::LocationError => error
    record_denied!(error.message)
    raise SearchError, error.message
  rescue GooglePlaces::ConfigurationError, GooglePlaces::RequestError => error
    record_unavailable!
    raise SearchError, error.message
  end

  private

  def validate_radius!
    raise SearchError, "Choose a search radius between 1 and 20 kilometres." unless @radius_meters.between?(1_000, MAX_RADIUS_METERS)
  end

  def normalise(places, resolved)
    preferred_place_id = @care_profile.location_preference&.preferred_hospital_place_id
    places.filter_map do |place|
      next if place["businessStatus"] == "CLOSED_PERMANENTLY"
      next if place["id"].blank? || place.dig("displayName", "text").blank?

      latitude = place.dig("location", "latitude")
      longitude = place.dig("location", "longitude")
      {
        place_id: place["id"],
        name: place.dig("displayName", "text"),
        address: place["formattedAddress"],
        distance_meters: latitude && longitude ? haversine_distance(resolved[:latitude], resolved[:longitude], latitude, longitude) : nil,
        phone_number: place["internationalPhoneNumber"],
        open_status: open_status(place),
        maps_url: place["googleMapsUri"],
        call_available: place["internationalPhoneNumber"].present?,
        directions_available: place["googleMapsUri"].present?,
        preferred: place["id"] == preferred_place_id,
        disclaimer: "Confirm services and availability directly with the hospital."
      }
    end.sort_by { |hospital| [ hospital[:preferred] ? 0 : 1, hospital[:distance_meters] || Float::INFINITY ] }.first(5)
  end

  def open_status(place)
    open_now = place.dig("currentOpeningHours", "openNow")
    return "Open now" if open_now == true
    return "Closed now" if open_now == false

    "Hours unavailable"
  end

  def haversine_distance(lat1, lng1, lat2, lng2)
    radians = Math::PI / 180
    lat_delta = (lat2.to_f - lat1.to_f) * radians
    lng_delta = (lng2.to_f - lng1.to_f) * radians
    a = Math.sin(lat_delta / 2)**2 + Math.cos(lat1.to_f * radians) * Math.cos(lat2.to_f * radians) * Math.sin(lng_delta / 2)**2
    (6_371_000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).round
  end

  def record!(resolved, result_count, status)
    event = HospitalSearchEvent.create!(
      actor_user: @actor, care_profile: @care_profile, location_source: @location_source,
      consent_basis: resolved.fetch(:consent_basis), country: @care_profile.country,
      searched_at: Time.current, result_count:, status:
    )
    AuditTrail.record!(
      action: "hospital_search.#{status}", actor: @actor, care_profile: @care_profile,
      metadata: { hospital_search_event_id: event.id, location_source: @location_source, result_count: }
    )
    event
  end

  def record_denied!(message)
    HospitalSearchEvent.create!(actor_user: @actor, care_profile: @care_profile, location_source: @location_source.presence || "manual_location", consent_basis: "not_granted", country: @care_profile.country, searched_at: Time.current, result_count: 0, status: "denied")
    AuditTrail.record!(action: "hospital_search.denied", actor: @actor, care_profile: @care_profile, metadata: { location_source: @location_source, reason: message })
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def record_unavailable!
    event = HospitalSearchEvent.create!(actor_user: @actor, care_profile: @care_profile, location_source: @location_source, consent_basis: "attempted", country: @care_profile.country, searched_at: Time.current, result_count: 0, status: "unavailable")
    AuditTrail.record!(action: "hospital_search.unavailable", actor: @actor, care_profile: @care_profile, metadata: { hospital_search_event_id: event.id, location_source: @location_source })
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
