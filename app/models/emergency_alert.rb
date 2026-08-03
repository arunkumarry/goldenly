class EmergencyAlert < ApplicationRecord
  include BelongsToCareProfile

  enum :status, { awaiting_confirmation: "awaiting_confirmation", confirmed: "confirmed", cancelled: "cancelled" }, default: :awaiting_confirmation

  has_many :sos_alert_deliveries, dependent: :destroy
end
