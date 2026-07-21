class User < ApplicationRecord
  has_many :members, dependent: :destroy
  has_many :authentication_tokens, dependent: :destroy

  normalizes :email_address, with: ->(email) { email&.strip&.downcase }
  normalizes :phone_number, with: ->(phone) { phone&.strip }

  validates :full_name, :country, presence: true
  validates :email_address, uniqueness: true, allow_nil: true
  validates :phone_number, uniqueness: true, allow_nil: true
  validate :email_or_phone_present

  def identifier
    email_address || phone_number
  end

  private

  def email_or_phone_present
    return if email_address.present? || phone_number.present?

    errors.add(:base, "Email address or phone number is required")
  end
end
