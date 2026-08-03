class TwilioMessaging
  def self.deliver_sms(to:, body:)
    return { status: "skipped", reason: "Twilio Messaging Service is not configured." } unless configured?

    message = client.messages.create(to:, messaging_service_sid: ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"), body:)
    { status: "delivered", provider_message_id: message.sid }
  rescue StandardError => error
    Rails.logger.warn("Twilio SMS delivery failed: #{error.class}")
    { status: "failed", reason: "SMS could not be sent." }
  end

  def self.configured?
    %w[TWILIO_ACCOUNT_SID TWILIO_API_KEY TWILIO_API_KEY_SECRET TWILIO_MESSAGING_SERVICE_SID].all? { |key| ENV[key].present? }
  end

  def self.client
    @client ||= Twilio::REST::Client.new(
      ENV.fetch("TWILIO_API_KEY"), ENV.fetch("TWILIO_API_KEY_SECRET"), ENV.fetch("TWILIO_ACCOUNT_SID")
    )
  end
  private_class_method :client
end
