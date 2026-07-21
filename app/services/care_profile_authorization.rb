class CareProfileAuthorization
  class NotAuthorized < StandardError; end

  def initialize(user, care_profile)
    @user = user
    @care_profile = care_profile
  end

  def link
    @link ||= @care_profile.active_link_for(@user)
  end

  def allows?(permission, capability = :view, emergency: false)
    link&.allows?(permission, capability, emergency: emergency) || false
  end

  def authorize!(permission, capability = :view, emergency: false)
    return true if allows?(permission, capability, emergency: emergency)

    raise NotAuthorized, "You do not have permission to #{capability} this part of #{@care_profile.full_name}'s care."
  end
end
