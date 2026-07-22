class CarePartnerService < ApplicationRecord
  MAXIMUM_SERVICES_PER_PARTNER = 3

  belongs_to :care_partner
  belongs_to :service_catalog

  enum :status, { pending: "pending", active: "active", paused: "paused", rejected: "rejected" }, default: :pending

  normalizes :service_zones, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }
  normalizes :languages, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }
  normalizes :service_modes, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }

  validates :max_concurrent_visits, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 20 }
  validate :collection_fields_are_arrays
  validate :coverage_place_is_a_hash
  validate :within_partner_service_limit, on: :create

  def covers_profile?(care_profile)
    return true if care_profile.blank?
    return within_travel_radius?(care_profile) if coordinate_coverage?
    return true if service_zones.blank?

    profile_values = [ care_profile.city, care_profile.region, care_profile.country, care_profile.country_code ].compact_blank.map(&:downcase)
    service_zones.any? { |zone| profile_values.include?(zone.downcase) }
  end

  def available_for?(time)
    return true if time.blank? || availability.blank? || availability["days"].blank?

    Array(availability["days"]).map(&:downcase).include?(time.strftime("%A").downcase)
  end

  def coverage_label
    coverage_place["address"].presence || service_zones.to_sentence
  end

  private

  def collection_fields_are_arrays
    %i[service_zones languages service_modes].each do |field|
      errors.add(field, "must be a list") unless public_send(field).is_a?(Array)
    end
  end

  def coverage_place_is_a_hash
    errors.add(:coverage_place, "must be location details") unless coverage_place.is_a?(Hash)
  end

  def coordinate_coverage?
    travel_radius_km.present? && coverage_coordinates.all?
  end

  def within_travel_radius?(care_profile)
    member_latitude = Float(care_profile.latitude)
    member_longitude = Float(care_profile.longitude)
    partner_latitude, partner_longitude = coverage_coordinates

    distance_in_km(partner_latitude, partner_longitude, member_latitude, member_longitude) <= travel_radius_km
  rescue ArgumentError, TypeError
    # Legacy profiles may not yet have map coordinates. Their selected
    # city/region/country remains a safe matching fallback.
    return true if service_zones.blank?

    profile_values = [ care_profile.city, care_profile.region, care_profile.country, care_profile.country_code ].compact_blank.map(&:downcase)
    service_zones.any? { |zone| profile_values.include?(zone.downcase) }
  end

  def coverage_coordinates
    [ Float(coverage_place["latitude"]), Float(coverage_place["longitude"]) ]
  rescue ArgumentError, TypeError
    [ nil, nil ]
  end

  def distance_in_km(latitude_a, longitude_a, latitude_b, longitude_b)
    latitude_delta = radians(latitude_b - latitude_a)
    longitude_delta = radians(longitude_b - longitude_a)
    origin_latitude = radians(latitude_a)
    destination_latitude = radians(latitude_b)
    haversine = Math.sin(latitude_delta / 2)**2 + Math.cos(origin_latitude) * Math.cos(destination_latitude) * Math.sin(longitude_delta / 2)**2

    6_371 * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine))
  end

  def radians(value)
    value * Math::PI / 180
  end

  def within_partner_service_limit
    return if care_partner.blank?
    return if care_partner.care_partner_services.where.not(id: id).count < MAXIMUM_SERVICES_PER_PARTNER

    errors.add(:base, "You can add up to #{MAXIMUM_SERVICES_PER_PARTNER} services.")
  end
end
