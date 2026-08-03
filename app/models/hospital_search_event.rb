class HospitalSearchEvent < ApplicationRecord
  include BelongsToCareProfile

  belongs_to :actor_user, class_name: "User", optional: true
  has_many :hospital_place_actions, dependent: :destroy

  enum :location_source, {
    current_location: "current_location",
    saved_address: "saved_address",
    manual_location: "manual_location",
    sos: "sos"
  }
  enum :status, {
    completed: "completed",
    no_results: "no_results",
    unavailable: "unavailable",
    denied: "denied"
  }

  validates :location_source, :consent_basis, :country, :searched_at, :status, presence: true
end
