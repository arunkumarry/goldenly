class ProfileInvitationIssuer
  def initialize(care_profile:, invited_by:, identifier:, delivery_channel:, invitation_kind: "claim", permissions: {})
    @care_profile = care_profile
    @invited_by = invited_by
    @identifier = AuthenticationIdentifier.normalize(identifier)
    @delivery_channel = delivery_channel
    @invitation_kind = invitation_kind
    @permissions = permissions.presence || {}
  end

  def issue!
    raw_token = SecureRandom.urlsafe_base64(32)
    invitation = ProfileInvitation.create!(
      care_profile: @care_profile,
      invited_by: @invited_by,
      contact_identifier: @identifier,
      delivery_channel: @delivery_channel,
      invitation_kind: @invitation_kind,
      permissions: @permissions,
      token_digest: digest(raw_token),
      expires_at: ProfileInvitation::EXPIRY.from_now
    )
    AuditTrail.record!(action: "profile_invitation.created", actor: @invited_by, care_profile: @care_profile, metadata: { invitation_id: invitation.id, kind: invitation.invitation_kind, delivery_channel: invitation.delivery_channel })
    [ invitation, raw_token ]
  end

  def self.find_active(token)
    ProfileInvitation.active.find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  private

  def digest(token)
    self.class.digest(token)
  end
end
