class TwilioVerify
  class ConfigurationError < StandardError; end

  def self.send_code(identifier)
    client.verify.v2.services(service_sid).verifications.create(to: identifier, channel: channel_for(identifier))
  end

  def self.approved?(identifier, code)
    verification = client.verify.v2.services(service_sid).verification_checks.create(to: identifier, code: code)
    verification.status == "approved"
  end

  def self.channel_for(identifier)
    identifier.include?("@") ? "email" : "sms"
  end

  def self.client
    raise ConfigurationError, "Twilio API credentials are not configured" unless account_sid.present? && api_key.present? && api_key_secret.present?

    @client ||= Twilio::REST::Client.new(api_key, api_key_secret, account_sid)
  end

  def self.service_sid
    ENV.fetch("TWILIO_VERIFY_SERVICE_SID")
  rescue KeyError
    raise ConfigurationError, "TWILIO_VERIFY_SERVICE_SID is not configured"
  end

  def self.account_sid = ENV["TWILIO_ACCOUNT_SID"]
  def self.api_key = ENV["TWILIO_API_KEY"]
  def self.api_key_secret = ENV["TWILIO_API_KEY_SECRET"]
end
