class CarePartnerModerationDecision
  class InvalidDecision < StandardError; end

  def initialize(care_partner_account, reviewer:, decision:, reason:, requested_sections: [], ai_assistance: {})
    @care_partner_account = care_partner_account
    @reviewer = reviewer
    @decision = decision.to_s
    @reason = reason
    @requested_sections = requested_sections
    @ai_assistance = ai_assistance
  end

  def apply!
    raise InvalidDecision, "A human review reason is required." if @reason.blank?
    raise InvalidDecision, "Only Goldenly reviewers can make this decision." unless @reviewer.can_review_care_partners?

    CarePartnerAccount.transaction do
      apply_status!
      ModeratorReview.create!(
        care_partner_account: @care_partner_account,
        reviewer: @reviewer,
        decision: @decision,
        reason: @reason,
        requested_sections: @requested_sections,
        ai_assistance: @ai_assistance.merge("ai_decision_maker" => false)
      )
    end
    AuditTrail.record!(
      action: "care_partner.moderator_#{@decision}",
      actor: @reviewer,
      metadata: { care_partner_account_id: @care_partner_account.id, requested_sections: @requested_sections }
    )
    @care_partner_account
  end

  private

  def apply_status!
    case @decision
    when "under_review", "changes_requested", "rejected", "suspended"
      @care_partner_account.transition_to!(@decision, note: @reason)
    when "approved"
      raise InvalidDecision, "Verify an identity document before approval." unless @care_partner_account.identity_verified?

      @care_partner_account.care_partner_services.pending.find_each do |service|
        eligible = !service.service_catalog.requires_professional_credential? || @care_partner_account.current_credential_for?(service.service_catalog)
        service.update!(status: eligible ? :active : :pending)
      end
      @care_partner_account.transition_to!(:approved, note: @reason)
      @care_partner_account.transition_to!(:active, note: @reason) if @care_partner_account.activation_ready?
    else
      raise InvalidDecision, "Unsupported moderator decision."
    end
  end
end
