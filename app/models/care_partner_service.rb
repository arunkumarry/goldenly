class CarePartnerService < ApplicationRecord
  belongs_to :care_partner_account
  belongs_to :service_catalog

  enum :status, { pending: "pending", active: "active", paused: "paused", rejected: "rejected" }, default: :pending

  normalizes :service_zones, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }
  normalizes :languages, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }
  normalizes :service_modes, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }

  validates :max_concurrent_visits, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 20 }
  validate :collection_fields_are_arrays

  def covers_profile?(care_profile)
    return true if care_profile.blank? || service_zones.blank?

    profile_values = [ care_profile.city, care_profile.region, care_profile.country, care_profile.country_code ].compact_blank.map(&:downcase)
    service_zones.any? { |zone| profile_values.include?(zone.downcase) }
  end

  def available_for?(time)
    return true if time.blank? || availability.blank? || availability["days"].blank?

    Array(availability["days"]).map(&:downcase).include?(time.strftime("%A").downcase)
  end

  private

  def collection_fields_are_arrays
    %i[service_zones languages service_modes].each do |field|
      errors.add(field, "must be a list") unless public_send(field).is_a?(Array)
    end
  end
end
