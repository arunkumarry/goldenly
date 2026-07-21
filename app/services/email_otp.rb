class EmailOtp
  TTL = 10.minutes
  MAX_ATTEMPTS = 5

  class DeliveryError < StandardError; end

  def self.send_code(identifier)
    code = format("%06d", SecureRandom.random_number(1_000_000))
    record = EmailVerificationCode.find_or_initialize_by(identifier: identifier)
    record.update!(code_digest: BCrypt::Password.create(code), expires_at: TTL.from_now, used_at: nil, attempts_count: 0)
    VerificationMailer.with(identifier: identifier, code: code).verification_code.deliver_now
  rescue StandardError => error
    raise DeliveryError, "We could not send the email verification code. #{error.message}"
  end

  def self.approved?(identifier, code)
    record = EmailVerificationCode.find_by(identifier: identifier)
    return false unless record

    record.with_lock do
      return false if record.used_at? || record.expires_at <= Time.current || record.attempts_count >= MAX_ATTEMPTS

      valid = BCrypt::Password.new(record.code_digest) == code.to_s
      record.increment!(:attempts_count)
      record.update!(used_at: Time.current) if valid
      valid
    end
  end
end
