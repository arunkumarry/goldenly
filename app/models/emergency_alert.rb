class EmergencyAlert < ApplicationRecord
  belongs_to :member

  enum :status, { awaiting_confirmation: "awaiting_confirmation", confirmed: "confirmed", cancelled: "cancelled" }, default: :awaiting_confirmation
end
