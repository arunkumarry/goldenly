module StructuredPlace
  extend ActiveSupport::Concern

  included do
    normalizes :country_code, with: ->(value) { value&.strip&.upcase }
    before_validation :sync_legacy_location_from_city
  end

  private

  # `location` remains the backwards-compatible city field used by existing
  # dashboards and mobile clients. New records additionally retain a dedicated
  # `city` column so the full address can be routed without parsing text later.
  def sync_legacy_location_from_city
    self.location = city if city.present?
  end
end
