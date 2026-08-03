class SosAlertDelivery < ApplicationRecord
  belongs_to :emergency_alert
  belongs_to :recipient_user, class_name: "User", optional: true

  enum :channel, { push: "push", sms: "sms" }
  enum :status, { delivered: "delivered", failed: "failed", skipped: "skipped" }

  validates :channel, :status, :recipient_label, :consent_basis, presence: true
end
