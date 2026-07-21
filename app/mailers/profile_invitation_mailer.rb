class ProfileInvitationMailer < ApplicationMailer
  def claim_profile
    @care_profile = params.fetch(:care_profile)
    @invited_by = params.fetch(:invited_by)
    @claim_url = params.fetch(:claim_url)

    mail(
      to: params.fetch(:recipient),
      subject: "Claim your Goldenly care profile"
    )
  end
end
