class CarePartnerAccount < ApplicationRecord
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
  enum :availability_status, { available: "available", paused: "paused" }, default: :paused
  enum :payout_status, { not_started: "not_started", pending: "pending", verified: "verified", blocked: "blocked" }, default: :not_started

  accepts_nested_attributes_for :profile

  validates :onboarding_step, inclusion: { in: 1..4 }

  def onboarding_missing_fields
    details = profile
    missing = []
    missing << "legal name" if details&.legal_name.blank?
    missing << "display name" if details&.display_name.blank?
    missing << "country" if details&.country_code.blank?
    missing << "residential address" if details&.address.blank?
    missing << "city" if details&.city.blank?
    missing << "date of birth" if details&.date_of_birth.blank?
    missing << "profile photo" unless details&.profile_photo&.attached?
    missing << "emergency contact" if details&.emergency_contact_name.blank? || details&.emergency_contact_phone.blank?
    missing << "preferred language" if details&.languages.blank?
    missing << "identity document" if verification_documents.empty?
    missing << "service selection" if care_partner_services.empty?
    missing << "service zone" unless care_partner_services.any? { |service| service.service_zones.present? }
    missing << "introduction video link" if details&.introduction_video_url.blank?
    missing << "terms acceptance" if terms_accepted_at.blank? || privacy_accepted_at.blank? || code_of_conduct_accepted_at.blank? || service_standards_accepted_at.blank?
    missing
  end

  def ready_to_submit?
    onboarding_missing_fields.empty?
  end

  def activation_ready?
    identity_verified? && payout_method_summary.present? && approved_services.exists?
  end

  def active_and_available?
    active? && available?
  end

  def approved_services
    care_partner_services.active
  end

  def eligible_for?(service_catalog, care_profile: nil, preferred_time: nil)
    return false unless active_and_available?

    partner_service = approved_services.find_by(service_catalog: service_catalog)
    return false unless partner_service&.available_for?(preferred_time)
    return false unless partner_service.covers_profile?(care_profile)
    return false if service_catalog.requires_professional_credential? && !current_credential_for?(service_catalog)
    return false unless has_capacity_for?(preferred_time)

    true
  end

  def current_credential_for?(service_catalog)
    credentials.approved.current.where(service_catalog: [ nil, service_catalog ]).exists?
  end

  def has_capacity_for?(preferred_time)
    return true if preferred_time.blank?

    service_assignments.active_work.joins(:service_request)
      .where(service_requests: { preferred_time: preferred_time.beginning_of_hour..preferred_time.end_of_hour })
      .count < care_partner_services.maximum(:max_concurrent_visits).to_i.clamp(1, 20)
  end

  def identity_verified?
    verification_documents.approved.current.exists?
  end
end
