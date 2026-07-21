class User < ApplicationRecord
  has_many :authentication_tokens, dependent: :destroy
  has_many :care_profile_links, dependent: :destroy
  has_many :care_profiles, through: :care_profile_links
  has_many :owned_care_profiles, class_name: "CareProfile", foreign_key: :owner_user_id, dependent: :nullify
  has_many :profile_invitations_sent, class_name: "ProfileInvitation", foreign_key: :invited_by_id, dependent: :destroy
  has_many :consent_records, class_name: "ConsentRecord", foreign_key: :actor_user_id, dependent: :nullify
  has_many :audit_events, class_name: "AuditEvent", foreign_key: :actor_user_id, dependent: :nullify

  normalizes :email_address, with: ->(email) { email&.strip&.downcase }
  normalizes :phone_number, with: ->(phone) { phone&.strip }

  validates :full_name, :country, presence: true
  validates :email_address, uniqueness: true, allow_nil: true
  validates :phone_number, uniqueness: true, allow_nil: true
  validate :email_or_phone_present

  def identifier
    email_address || phone_number
  end

  def active_care_profile_links
    care_profile_links.active.includes(:care_profile)
  end

  def care_profile_link_for(care_profile)
    active_care_profile_links.find_by(care_profile: care_profile)
  end

  private

  def email_or_phone_present
    return if email_address.present? || phone_number.present?

    errors.add(:base, "Email address or phone number is required")
  end
end
