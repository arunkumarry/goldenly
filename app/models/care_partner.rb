class CarePartner < ApplicationRecord
  include CarePartnerLifecycle

  belongs_to :user
  has_one :profile, class_name: "CarePartnerProfile", dependent: :destroy
  has_many :verification_documents, class_name: "CarePartnerVerificationDocument", dependent: :destroy
  has_many :credentials, class_name: "CarePartnerCredential", dependent: :destroy
  has_many :care_partner_services, dependent: :destroy
  has_many :service_catalogs, through: :care_partner_services
  has_many :service_offers, dependent: :destroy
  has_many :service_assignments, dependent: :restrict_with_error
  has_many :earnings_ledger_entries, dependent: :restrict_with_error
  has_many :moderator_reviews, dependent: :restrict_with_error

  enum :application_status, {
    draft: "draft", submitted: "submitted", under_review: "under_review",
    changes_requested: "changes_requested", approved: "approved", active: "active",
    suspended: "suspended", rejected: "rejected"
  }, default: :draft
  enum :verification_status, {
    pending: "pending", approved: "approved", changes_requested: "changes_requested", rejected: "rejected"
  }, prefix: :verification, default: :pending
  enum :availability_status, { available: "available", paused: "paused" }, default: :paused
  enum :payout_status, { not_started: "not_started", pending: "pending", verified: "verified", blocked: "blocked" }, default: :not_started

  accepts_nested_attributes_for :profile

  validates :onboarding_step, inclusion: { in: 1..4 }

  def onboarding_missing_fields
    CarePartnerOnboardingProgress.new(self).all_missing_fields
  end

  def ready_to_submit?
    onboarding_missing_fields.empty?
  end

  def activation_ready?
    verification_approved? && payout_method_summary.present? && approved_services.exists?
  end

  def activate_if_ready!
    return false unless approved? && activation_ready?

    transition_to!(:active)
    true
  end

  def active_and_available?
    active? && available?
  end

  def approved_services
    care_partner_services.active
  end

  def eligible_for?(service_catalog, care_profile: nil, preferred_time: nil)
    return false unless active_and_available? && verification_approved?

    partner_service = approved_services.find_by(service_catalog: service_catalog)
    return false unless partner_service&.available_for?(preferred_time)
    return false unless partner_service.covers_profile?(care_profile)
    return false unless has_capacity_for?(preferred_time)

    true
  end

  def has_capacity_for?(preferred_time)
    return true if preferred_time.blank?

    service_assignments.active_work.joins(:service_request)
      .where(service_requests: { preferred_time: preferred_time.beginning_of_hour..preferred_time.end_of_hour })
      .count < care_partner_services.maximum(:max_concurrent_visits).to_i.clamp(1, 20)
  end

  # Evidence is kept on associated records, but a moderator's decision here is
  # the single source of truth for whether the Care Partner is verified.
  def approve_verification!
    update!(verification_status: :approved, verified_at: Time.current)
  end

  def identity_verified?
    verification_approved?
  end
end
