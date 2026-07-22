class CarePartnerApplicationSubmission
  class IncompleteApplication < StandardError; end

  def initialize(care_partner, actor:)
    @care_partner = care_partner
    @actor = actor
  end

  def submit!
    raise IncompleteApplication, missing_message unless @care_partner.ready_to_submit?

    @care_partner.transition_to!(:submitted)
    AuditTrail.record!(
      action: "care_partner.application_submitted",
      actor: @actor,
      metadata: { care_partner_id: @care_partner.id }
    )
    @care_partner
  end

  private

  def missing_message
    "Add #{@care_partner.onboarding_missing_fields.to_sentence} before submitting."
  end
end
