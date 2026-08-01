class CareProfileLocationPreference < ApplicationRecord
  include BelongsToCareProfile

  enum :location_sharing_preference, {
    ask_each_time: "ask_each_time",
    allow_saved_address: "allow_saved_address"
  }, default: :ask_each_time

  validates :location_sharing_preference, presence: true
end
