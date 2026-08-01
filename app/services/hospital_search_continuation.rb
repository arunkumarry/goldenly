class HospitalSearchContinuation
  PURPOSE = "hospital-search-continuation".freeze

  def self.issue(care_profile:, location_source:, location:)
    encryptor.encrypt_and_sign(
      { "care_profile_id" => care_profile.id, "location_source" => location_source, "location" => location.slice(:latitude, :longitude, :label) },
      expires_in: 10.minutes
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
