class User < ApplicationRecord
  include StructuredPlace

  has_many :authentication_tokens, dependent: :destroy
  has_many :device_push_tokens, dependent: :destroy
  has_many :care_profile_links, dependent: :destroy
  has_many :care_profiles, through: :care_profile_links
  has_many :owned_care_profiles, class_name: "CareProfile", foreign_key: :owner_user_id, dependent: :nullify
  has_many :profile_invitations_sent, class_name: "ProfileInvitation", foreign_key: :invited_by_id, dependent: :destroy
  has_many :consent_records, class_name: "ConsentRecord", foreign_key: :actor_user_id, dependent: :nullify
  has_many :audit_events, class_name: "AuditEvent", foreign_key: :actor_user_id, dependent: :nullify
  has_one :care_partner_account, dependent: :destroy
  has_many :moderator_reviews, foreign_key: :reviewer_id, dependent: :restrict_with_error

  normalizes :email_address, with: ->(email) { email&.strip&.downcase }
  normalizes :phone_number, with: ->(phone) { phone&.strip }

  validates :full_name, :country, presence: true
  validates :email_address, uniqueness: true, allow_nil: true
  validates :phone_number, uniqueness: true, allow_nil: true
  validate :email_or_phone_present

  enum :platform_role, {
    member: "member", moderator: "moderator", operations_manager: "operations_manager", finance_reviewer: "finance_reviewer"
  }, default: :member

  def identifier
    email_address || phone_number
  end

  def active_care_profile_links
    care_profile_links.active.includes(:care_profile)
  end

  def care_profile_link_for(care_profile)
    active_care_profile_links.find_by(care_profile: care_profile)
  end

  def can_review_care_partners?
    moderator? || operations_manager?
  end

  def can_manage_care_partner_payouts?
    operations_manager? || finance_reviewer?
  end

  private

  def email_or_phone_present
    return if email_address.present? || phone_number.present?

    errors.add(:base, "Email address or phone number is required")
  end
end
