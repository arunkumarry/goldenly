class HospitalSearch::LocationResolver
  class LocationError < StandardError; end

  SOURCES = %w[current_location saved_address manual_location sos].freeze

  def initialize(care_profile:, actor:, location_source:, location: nil, emergency: false)
    @care_profile = care_profile
    @actor = actor
    @location_source = location_source.to_s
    @location = location || {}
    @emergency = emergency
  end

  def resolve
    raise LocationError, "Choose how Goldenly should use a location." unless SOURCES.include?(@location_source)

    case @location_source
    when "saved_address" then saved_address
    when "current_location" then supplied_location("your current location", owner_only: true)
    when "manual_location" then supplied_location("the selected address")
    when "sos" then supplied_location("the SOS location")
    end
  end

  private

  def saved_address
    ensure_permission!(:view)
    latitude = @care_profile.latitude
    longitude = @care_profile.longitude
    raise LocationError, "#{@care_profile.full_name}'s saved address does not have a map location yet. Choose another address." if latitude.blank? || longitude.blank?

    {
      latitude: latitude.to_f,
      longitude: longitude.to_f,
      label: "Near #{@care_profile.full_name}'s saved address",
      consent_basis: "authorised_saved_address"
    }
  end

  def supplied_location(label, owner_only: false)
    ensure_permission!(:view, emergency: @location_source == "sos")
    if owner_only && !@care_profile.owned_by?(@actor)
      raise LocationError, "Current device location can only be used for your own care profile. Choose the saved or another authorised address."
    end

    latitude = Float(@location[:latitude] || @location["latitude"])
    longitude = Float(@location[:longitude] || @location["longitude"])
    raise LocationError, "Choose a valid #{label}." unless latitude.between?(-90, 90) && longitude.between?(-180, 180)

    {
      latitude: latitude,
      longitude: longitude,
      label: @location[:label].presence || @location["label"].presence || "Near #{label}",
      consent_basis: @location_source == "sos" ? "confirmed_sos_location" : "one_time_#{@location_source}"
    }
  rescue ArgumentError, TypeError
    raise LocationError, "Choose a valid #{label}."
  end

  def ensure_permission!(capability, emergency: false)
    CareProfileAuthorization.new(@actor, @care_profile).authorize!(:location_access, capability, emergency:)
  end
end
