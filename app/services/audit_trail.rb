class AuditTrail
  def self.record!(action:, actor:, care_profile: nil, metadata: {})
    AuditEvent.create!(
      action: action,
      actor_user: actor,
      care_profile: care_profile,
      metadata: metadata,
      occurred_at: Time.current
    )
  end
end
