class TrustedCircleController < ApplicationController
  before_action -> { require_care_profile_permission!(:trusted_circle, :manage) }

  def index
    @access_links = current_care_profile.care_profile_links.active.includes(:user).order("users.full_name")
    @invitations = current_care_profile.profile_invitations.order(created_at: :desc)
    @claimable_profiles = current_user.active_care_profile_links.includes(:care_profile).select do |link|
      !link.care_profile.owned_by?(current_user) && %w[unclaimed assisted].include?(link.care_profile.state)
    end
    selected_profile = @claimable_profiles.find { |link| link.care_profile_id == current_care_profile.id }&.care_profile || @claimable_profiles.first&.care_profile
    @invitation = ProfileInvitation.new(
      care_profile_id: selected_profile&.id,
      contact_identifier: selected_profile&.phone_number,
      delivery_channel: "sms",
      invitation_kind: "claim"
    )
  end
end
