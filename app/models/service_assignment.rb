class ServiceAssignment < ApplicationRecord
  belongs_to :service_request
  belongs_to :care_partner
  has_one :visit_submission, dependent: :destroy
  has_one :earnings_ledger_entry, dependent: :destroy

  enum :status, {
    assigned: "assigned", upcoming: "upcoming", checked_in: "checked_in", in_progress: "in_progress",
    submitted_for_confirmation: "submitted_for_confirmation", confirmed: "confirmed", disputed: "disputed",
    cancelled: "cancelled", escalated: "escalated"
  }, default: :assigned

  scope :active_work, -> { where(status: %w[assigned upcoming checked_in in_progress]) }

  validates :accepted_at, presence: true

  def member_confirmation_code_matches?(code)
    return false if member_confirmation_code_digest.blank? || member_confirmation_expires_at.blank? || member_confirmation_expires_at.past?

    ActiveSupport::SecurityUtils.secure_compare(
      member_confirmation_code_digest,
      Digest::SHA256.hexdigest(code.to_s)
    )
  end
end
