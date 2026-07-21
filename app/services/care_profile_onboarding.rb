class CareProfileOnboarding
  def initialize(account_user:, source: "web")
    @account_user = account_user
    @source = source
  end

  def create_self!(attributes)
    CareProfile.transaction do
      profile = CareProfile.create!(profile_attributes(attributes).merge(owner: @account_user, state: "claimed"))
      create_link!(profile, relationship: "self", permissions: CareProfilePermissions.full_access)
      ConsentRecord.create!(care_profile: profile, actor_user: @account_user, subject: "care recipient", purpose: "self care setup", permissions: CareProfilePermissions.full_access, source: @source, captured_at: Time.current)
      AuditTrail.record!(action: "care_profile.created_self", actor: @account_user, care_profile: profile)
      profile
    end
  end

  def create_for_someone_else!(attributes, relationship:, consent_basis:, permissions: CareProfilePermissions.full_access, state: "unclaimed")
    CareProfile.transaction do
      profile = CareProfile.create!(profile_attributes(attributes).merge(state: state, consent_basis: consent_basis))
      create_link!(profile, relationship: relationship, permissions: permissions)
      ConsentRecord.create!(care_profile: profile, actor_user: @account_user, subject: "care recipient", purpose: "initial coordinated care setup", permissions: permissions, source: @source, captured_at: Time.current)
      AuditTrail.record!(action: "care_profile.created_for_other", actor: @account_user, care_profile: profile, metadata: { relationship: relationship, state: state })
      profile
    end
  end

  private

  def profile_attributes(attributes)
    # Web signup data is stored in the session, which returns string keys.
    # Normalise it before applying the same onboarding service used by the API.
    attributes.to_h.symbolize_keys.slice(:full_name, :phone_number, :preferred_language, :mobility_needs, :emergency_contact_name, :emergency_contact_phone, :country, :location, :accessibility_preferences)
  end

  def create_link!(profile, relationship:, permissions:)
    CareProfileLink.create!(user: @account_user, care_profile: profile, relationship_to_person: relationship, permissions: permissions, status: "active")
  end
end
