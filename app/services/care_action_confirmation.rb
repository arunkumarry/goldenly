class CareActionConfirmation
  PURPOSE = "care-agent-action".freeze

  def self.issue(care_profile:, action:)
    verifier.generate({ "care_profile_id" => care_profile.id, "action" => action }, expires_in: 10.minutes)
  end

  def self.verify(token)
    verifier.verified(token)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def self.verifier
    Rails.application.message_verifier(PURPOSE)
  end
  private_class_method :verifier
end
