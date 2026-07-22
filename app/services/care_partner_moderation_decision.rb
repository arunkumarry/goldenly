class CarePartnerModerationDecision
  class InvalidDecision < StandardError; end

  def initialize(care_partner, reviewer:, decision:, reason:, requested_sections: [], ai_assistance: {})
    @care_partner = care_partner
    @reviewer = reviewer
    @decision = decision.to_s
    @reason = reason
    @requested_sections = requested_sections
    @ai_assistance = ai_assistance
  end

  def apply!
    raise InvalidDecision, "A human review reason is required." if @reason.blank?
    raise InvalidDecision, "Only Goldenly reviewers can make this decision." unless @reviewer.can_review_care_partners?

    CarePartner.transaction do
      apply_status!
      ModeratorReview.create!(
        care_partner: @care_partner,
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
      metadata: { care_partner_id: @care_partner.id, requested_sections: @requested_sections }
    )
    @care_partner
  end

  private

  def apply_status!
    case @decision
    when "under_review", "changes_requested", "rejected", "suspended"
      @care_partner.update!(verification_status: @decision) if %w[changes_requested rejected].include?(@decision)
      @care_partner.transition_to!(@decision, note: @reason)
    when "approved"
      raise InvalidDecision, "Review at least one identity document before approval." if @care_partner.verification_documents.empty?

      @care_partner.approve_verification!
      @care_partner.care_partner_services.pending.find_each { |service| service.update!(status: :active) }
      @care_partner.transition_to!(:approved, note: @reason)
      @care_partner.activate_if_ready!
    else
      raise InvalidDecision, "Unsupported moderator decision."
    end
  end
end
