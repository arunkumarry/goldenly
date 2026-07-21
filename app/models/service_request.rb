class ServiceRequest < ApplicationRecord
  belongs_to :member

  enum :status, { awaiting_confirmation: "awaiting_confirmation", requested: "requested", provider_assigned: "provider_assigned", completed: "completed", cancelled: "cancelled" }, default: :awaiting_confirmation

  validates :service_type, presence: true
end
