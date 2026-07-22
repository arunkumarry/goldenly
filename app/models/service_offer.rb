class ServiceOffer < ApplicationRecord
  belongs_to :service_request
  belongs_to :care_partner_account

  enum :status, { offered: "offered", accepted: "accepted", declined: "declined", expired: "expired", matched: "matched" }, default: :offered

  validates :offered_at, presence: true

  scope :open, -> { offered.where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def open?
    offered? && !expired?
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at <= Time.current)
  end
end
