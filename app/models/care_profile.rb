class CareProfile < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :owner_user_id, optional: true

  has_many :care_profile_links, dependent: :destroy
  has_many :account_users, through: :care_profile_links, source: :user
  has_many :profile_invitations, dependent: :destroy
  has_many :consent_records, dependent: :destroy
  # Audit events are immutable. Keep the event if a profile is removed, while
  # clearing its profile reference so the foreign key remains valid.
  has_many :audit_events, dependent: :nullify
  has_many :reminders, dependent: :destroy
  has_many :service_requests, dependent: :destroy
  has_many :trusted_contacts, dependent: :destroy
  has_many :emergency_alerts, dependent: :destroy

  enum :state, { draft: "draft", unclaimed: "unclaimed", claimed: "claimed", assisted: "assisted", archived: "archived" }, default: :unclaimed

  validates :full_name, :preferred_language, :country, presence: true

  def owned_by?(user)
    owner_user_id == user.id
  end

  def active_link_for(user)
    care_profile_links.active.find_by(user: user)
  end
end
