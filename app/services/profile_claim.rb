class ProfileClaim
  class ClaimError < StandardError; end

  def initialize(invitation:, account_user:, retain_existing_access: true, source: "web")
    @invitation = invitation
    @account_user = account_user
    @retain_existing_access = ActiveModel::Type::Boolean.new.cast(retain_existing_access)
    @source = source
  end

  def claim!
    raise ClaimError, "This invitation is no longer active." unless @invitation.active?

    CareProfile.transaction do
      if @invitation.claim?
        claim_profile!
      else
        grant_access!
      end
      @invitation.update!(accepted_at: Time.current)
      AuditTrail.record!(action: "profile_invitation.accepted", actor: @account_user, care_profile: @invitation.care_profile, metadata: { invitation_id: @invitation.id, kind: @invitation.invitation_kind })
      @invitation.care_profile
    end
  end

  private

  def claim_profile!
    profile = @invitation.care_profile
    profile.update!(owner: @account_user, state: "claimed")
    CareProfileLink.find_or_initialize_by(user: @account_user, care_profile: profile).tap do |link|
      link.relationship_to_person = "self"
      link.status = "active"
      link.permissions = CareProfilePermissions.full_access
      link.save!
    end
    profile.care_profile_links.where.not(user: @account_user).update_all(status: "revoked") unless @retain_existing_access
    ConsentRecord.create!(care_profile: profile, actor_user: @account_user, subject: "care recipient", purpose: "profile claim and access review", permissions: @retain_existing_access ? { "existing_access_retained" => "yes" } : { "existing_access_retained" => "no" }, source: @source, captured_at: Time.current)
  end

  def grant_access!
    CareProfileLink.find_or_initialize_by(user: @account_user, care_profile: @invitation.care_profile).tap do |link|
      link.relationship_to_person = "trusted_contact"
      link.status = "active"
      link.permissions = @invitation.permissions
      link.save!
    end
  end
end
