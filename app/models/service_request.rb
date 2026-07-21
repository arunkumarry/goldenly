class ServiceRequest < ApplicationRecord
  include BelongsToCareProfile

  belongs_to :service_catalog

  enum :status, { awaiting_confirmation: "awaiting_confirmation", requested: "requested", provider_assigned: "provider_assigned", completed: "completed", cancelled: "cancelled" }, default: :awaiting_confirmation

  validates :service_type, presence: true
  validate :service_catalog_is_available

  before_validation :sync_service_type_from_catalog

  private

  def sync_service_type_from_catalog
    self.service_type = service_catalog.name if service_catalog
  end

  def service_catalog_is_available
    errors.add(:service_catalog, "is not available") if service_catalog && !service_catalog.active?
  end
end
