class ProfileInvitationDelivery
  class DeliveryError < StandardError; end

  def initialize(invitation:, token:, claim_url:)
    @invitation = invitation
    @token = token
    @claim_url = claim_url
  end

  def deliver!
    return :link_ready unless @invitation.email?

    ProfileInvitationMailer.with(
      recipient: @invitation.contact_identifier,
      care_profile: @invitation.care_profile,
      invited_by: @invitation.invited_by,
      claim_url: @claim_url
    ).claim_profile.deliver_now
    :email_sent
  rescue StandardError => error
    raise DeliveryError, "We could not email this invitation. #{error.message}"
  end
end
