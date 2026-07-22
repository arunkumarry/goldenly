class CarePartnerVerificationDocument < ApplicationRecord
  belongs_to :care_partner_account

  enum :verification_status, { pending: "pending", approved: "approved", changes_requested: "changes_requested", rejected: "rejected" }, default: :pending

  validates :document_type, presence: true
  validates :country_code, length: { is: 2 }, allow_blank: true

  scope :current, -> { where("expires_on IS NULL OR expires_on >= ?", Date.current) }
end
