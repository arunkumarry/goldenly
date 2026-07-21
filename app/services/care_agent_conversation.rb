class CareAgentConversation
  PURPOSE = "care-agent-conversation".freeze

  def self.issue(care_profile:, pending_service: nil, history: [])
    encryptor.encrypt_and_sign(
      {
        "care_profile_id" => care_profile.id,
        "pending_service" => pending_service,
        "history" => history.last(6)
      },
      expires_in: 15.minutes
    )
  end

  def self.verify(token)
    encryptor.decrypt_and_verify(token)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def self.encryptor
    @encryptor ||= begin
      key = Rails.application.key_generator.generate_key(PURPOSE, ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
  private_class_method :encryptor
end
