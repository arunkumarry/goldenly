class OneTimeVerification
  def self.send_code(identifier)
    AuthenticationIdentifier.email?(identifier) ? EmailOtp.send_code(identifier) : TwilioVerify.send_code(identifier)
  end

  def self.approved?(identifier, code)
    AuthenticationIdentifier.email?(identifier) ? EmailOtp.approved?(identifier, code) : TwilioVerify.approved?(identifier, code)
  end

  def self.channel_for(identifier)
    AuthenticationIdentifier.email?(identifier) ? "email" : "sms"
  end
end
