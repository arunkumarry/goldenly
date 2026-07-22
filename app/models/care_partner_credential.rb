class CarePartnerCredential < ApplicationRecord
  belongs_to :care_partner
  belongs_to :service_catalog, optional: true

  enum :verification_status, { pending: "pending", approved: "approved", changes_requested: "changes_requested", rejected: "rejected" }, default: :pending

  validates :credential_type, presence: true

  scope :current, -> { where("expires_on IS NULL OR expires_on >= ?", Date.current) }
end
