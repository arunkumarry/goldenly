class CarePartnerApplicationSubmission
  class IncompleteApplication < StandardError; end

  def initialize(care_partner_account, actor:)
    @care_partner_account = care_partner_account
    @actor = actor
  end

  def submit!
    raise IncompleteApplication, missing_message unless @care_partner_account.ready_to_submit?

    @care_partner_account.transition_to!(:submitted)
    AuditTrail.record!(
      action: "care_partner.application_submitted",
      actor: @actor,
      metadata: { care_partner_account_id: @care_partner_account.id }
    )
    @care_partner_account
  end

  private

  def missing_message
    "Add #{@care_partner_account.onboarding_missing_fields.to_sentence} before submitting."
  end
end
