class CarePartnerMemberConfirmation
  class InvalidConfirmation < StandardError; end

  def initialize(service_assignment, actor:)
    @service_assignment = service_assignment
    @actor = actor
  end

  def confirm!(code: nil)
    finalise!(confirmed: true, code: code)
  end

  def dispute!(reason:)
    raise InvalidConfirmation, "Please tell us what needs attention." if reason.blank?

    finalise!(confirmed: false, reason: reason)
  end

  private

  def finalise!(confirmed:, code: nil, reason: nil)
    ServiceAssignment.transaction do
      @service_assignment.lock!
      unless @service_assignment.submitted_for_confirmation?
        raise InvalidConfirmation, "This visit is not ready for confirmation."
      end
      if code.present? && !@service_assignment.member_confirmation_code_matches?(code)
        raise InvalidConfirmation, "That confirmation code has expired or is incorrect."
      end

      if confirmed
        @service_assignment.update!(status: :confirmed, member_confirmed_at: Time.current, completion_outcome: "confirmed")
        @service_assignment.service_request.update!(status: :confirmed, confirmed_at: Time.current)
        @service_assignment.earnings_ledger_entry.update!(status: :available, available_at: Time.current)
      else
        @service_assignment.update!(status: :disputed, completion_outcome: "disputed", escalation_reason: reason)
        @service_assignment.service_request.update!(status: :disputed)
        @service_assignment.earnings_ledger_entry.update!(status: :on_hold, review_note: reason)
      end
    end
    AuditTrail.record!(
      action: confirmed ? "care_partner.visit_confirmed" : "care_partner.visit_disputed",
      actor: @actor,
      care_profile: @service_assignment.service_request.care_profile,
      metadata: { service_assignment_id: @service_assignment.id, reason: reason }
    )
    @service_assignment
  end
end
