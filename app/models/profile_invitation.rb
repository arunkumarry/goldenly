class ProfileInvitation < ApplicationRecord
  EXPIRY = 7.days

  belongs_to :care_profile
  belongs_to :invited_by, class_name: "User"

  enum :delivery_channel, { sms: "sms", email: "email", whatsapp: "whatsapp" }, default: :sms
  enum :invitation_kind, { claim: "claim", access: "access" }, default: :claim

  scope :active, -> { where(accepted_at: nil, cancelled_at: nil).where("expires_at > ?", Time.current) }

  validates :contact_identifier, :token_digest, :expires_at, presence: true
  validate :contact_matches_delivery_channel
  validate :permissions_are_recognised

  def active?
    accepted_at.nil? && cancelled_at.nil? && expires_at.future?
  end

  private

  def contact_matches_delivery_channel
    return if contact_identifier.blank?

    if delivery_channel == "email" && !AuthenticationIdentifier.email?(contact_identifier)
      errors.add(:contact_identifier, "must be an email address when sending by email")
    elsif delivery_channel != "email" && AuthenticationIdentifier.email?(contact_identifier)
      errors.add(:contact_identifier, "must be a phone number when sending by SMS or WhatsApp")
    end
  end

  def permissions_are_recognised
    permissions.each do |permission, level|
      errors.add(:permissions, "contains an unsupported permission") unless CareProfilePermissions::CATALOGUE.include?(permission.to_s) && CareProfilePermissions::LEVELS.include?(level.to_s)
    end
  end
end
