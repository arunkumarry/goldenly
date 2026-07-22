class ServiceRequest < ApplicationRecord
  include BelongsToCareProfile

  belongs_to :service_catalog
  has_many :service_offers, dependent: :destroy
  has_one :service_assignment, dependent: :destroy

  enum :status, {
    awaiting_confirmation: "awaiting_confirmation", requested: "requested", provider_assigned: "provider_assigned",
    checked_in: "checked_in", in_progress: "in_progress", submitted_for_confirmation: "submitted_for_confirmation",
    confirmed: "confirmed", completed: "completed", disputed: "disputed", escalated: "escalated", cancelled: "cancelled"
  }, default: :awaiting_confirmation

  validates :service_type, presence: true
  validate :service_catalog_is_available

  before_validation :sync_service_type_from_catalog
  after_commit :schedule_notification, on: %i[create update], if: :should_schedule_notification?

  private

  def sync_service_type_from_catalog
    self.service_type = service_catalog.name if service_catalog
  end

  def service_catalog_is_available
    errors.add(:service_catalog, "is not available") if service_catalog && !service_catalog.active?
  end

  def schedule_notification
    return unless notification_eligible? && preferred_time.present?

    notification_time = preferred_time - 30.minutes
    return unless notification_time.future?

    CareServiceRequestNotificationJob.set(wait_until: notification_time).perform_later(id, preferred_time.to_i)
  end

  def should_schedule_notification?
    saved_change_to_preferred_time? || saved_change_to_status?
  end

  def notification_eligible?
    requested? || provider_assigned?
  end
end
