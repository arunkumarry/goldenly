class MobileTokenIssuer
  ACCESS_TOKEN_TTL = 15.minutes
  REFRESH_TOKEN_TTL = 30.days

  def initialize(user)
    @user = user
  end

  def issue
    raw_refresh_token = SecureRandom.urlsafe_base64(48)
    AuthenticationToken.create!(user: @user, token_digest: digest(raw_refresh_token), expires_at: REFRESH_TOKEN_TTL.from_now)
    { access_token: access_token, refresh_token: raw_refresh_token, token_type: "Bearer", expires_in: ACCESS_TOKEN_TTL.to_i }
  end

  def self.refresh(raw_refresh_token)
    token = AuthenticationToken.active.find_by(token_digest: digest(raw_refresh_token))
    return unless token

    token.update!(revoked_at: Time.current)
    new(token.user).issue
  end

  private

  def access_token
    JWT.encode({ sub: @user.id, exp: ACCESS_TOKEN_TTL.from_now.to_i, iat: Time.current.to_i, type: "access" }, Rails.application.secret_key_base, "HS256")
  end

  def digest(token)
    self.class.digest(token)
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end
end
