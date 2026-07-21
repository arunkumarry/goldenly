class AuthenticationIdentifier
  class InvalidIdentifier < StandardError; end

  def self.normalize(value)
    identifier = value.to_s.strip
    return identifier.downcase if identifier.match?(URI::MailTo::EMAIL_REGEXP)
    return identifier if identifier.match?(/\A\+[1-9]\d{7,14}\z/)

    raise InvalidIdentifier, "Enter a valid email address or phone number in international format, for example +14155552671."
  end

  def self.email?(identifier)
    identifier.include?("@")
  end

  def self.find_user(identifier)
    email?(identifier) ? User.find_by(email_address: identifier) : User.find_by(phone_number: identifier)
  end

  def self.assign(user, identifier)
    email?(identifier) ? user.email_address = identifier : user.phone_number = identifier
  end
end
