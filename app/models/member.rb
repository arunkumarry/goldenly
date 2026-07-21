class Member < ApplicationRecord
  belongs_to :user

  has_many :reminders, dependent: :destroy
  has_many :service_requests, dependent: :destroy
  has_many :trusted_contacts, dependent: :destroy
  has_many :emergency_alerts, dependent: :destroy

  validates :full_name, :preferred_language, :relationship_to_user, :country, presence: true
end
