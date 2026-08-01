class HospitalPlaceAction < ApplicationRecord
  belongs_to :hospital_search_event

  enum :action_type, { call: "call", directions: "directions", maps_view: "maps_view" }

  validates :google_place_id, :action_type, :initiated_at, presence: true
end
