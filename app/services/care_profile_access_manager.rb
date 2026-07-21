class CareProfileAccessManager
  class AccessError < StandardError; end

  def initialize(actor:, care_profile:)
    @actor = actor
    @care_profile = care_profile
    @authorization = CareProfileAuthorization.new(actor, care_profile)
  end

  def invite!(identifier:, delivery_channel:, invitation_kind:, permissions: {})
    @authorization.authorize!(:trusted_circle, :manage)
    validate_permissions!(permissions) if invitation_kind == "access"
    ProfileInvitationIssuer.new(care_profile: @care_profile, invited_by: @actor, identifier: identifier, delivery_channel: delivery_channel, invitation_kind: invitation_kind, permissions: permissions).issue!
  end

  def update_link!(link:, permissions:)
    @authorization.authorize!(:trusted_circle, :manage)
    raise AccessError, "You cannot change the profile owner's access." if link.owner?

    validate_permissions!(permissions)
    link.update!(permissions: permissions, status: "active")
    AuditTrail.record!(action: "care_profile_link.permissions_changed", actor: @actor, care_profile: @care_profile, metadata: { link_id: link.id, permissions: permissions })
    link
  end

  private

  def validate_permissions!(permissions)
    raise AccessError, "You cannot grant access broader than your own." unless @authorization.link&.can_grant?(permissions)
  end
end
