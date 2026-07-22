class ModeratorReview < ApplicationRecord
  belongs_to :care_partner
  belongs_to :reviewer, class_name: "User"

  enum :decision, {
    under_review: "under_review", changes_requested: "changes_requested", approved: "approved",
    rejected: "rejected", suspended: "suspended", payout_released: "payout_released"
  }

  validates :reason, presence: true
end
