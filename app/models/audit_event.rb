class AuditEvent < ApplicationRecord
  include ImmutableAuditEvent

  belongs_to :actor_user, class_name: "User", optional: true
  belongs_to :care_profile, optional: true

  validates :action, :occurred_at, presence: true
end
