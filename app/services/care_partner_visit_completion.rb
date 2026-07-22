class CarePartnerVisitCompletion
  CONFIRMATION_CODE_LIFETIME = 24.hours

  def initialize(service_assignment, actor:)
    @service_assignment = service_assignment
    @actor = actor
  end

  def check_in!
    transition!("checked_in", checked_in_at: Time.current, service_request_status: :checked_in)
  end

  def start!
    transition!("in_progress", started_at: Time.current, service_request_status: :in_progress)
  end

  def submit!(checklist:, notes:, evidence: [], follow_up_needed: nil, escalation: false)
    code = format("%06d", SecureRandom.random_number(1_000_000))
    ServiceAssignment.transaction do
      @service_assignment.lock!
      raise ActiveRecord::RecordInvalid, @service_assignment unless @service_assignment.in_progress? || @service_assignment.checked_in? || @service_assignment.assigned?

      @service_assignment.create_visit_submission!(
        checklist: checklist.presence || {}, notes: notes, evidence: evidence,
        escalation_status: escalation ? :raised : :not_escalated, follow_up_needed: follow_up_needed,
        submitted_at: Time.current
      )
      assignment_attributes = {
        status: escalation ? :escalated : :submitted_for_confirmation,
        completed_at: Time.current,
        member_confirmation_code_digest: Digest::SHA256.hexdigest(code),
        member_confirmation_code_hint: code.last(2),
        member_confirmation_expires_at: CONFIRMATION_CODE_LIFETIME.from_now
      }
      assignment_attributes[:escalation_reason] = follow_up_needed if escalation
      @service_assignment.update!(assignment_attributes)
      @service_assignment.service_request.update!(status: escalation ? :escalated : :submitted_for_confirmation)
      @service_assignment.earnings_ledger_entry.update!(status: escalation ? :on_hold : :pending_confirmation)
    end
    AuditTrail.record!(
      action: "care_partner.visit_submitted",
      actor: @actor,
      care_profile: @service_assignment.service_request.care_profile,
      metadata: { service_assignment_id: @service_assignment.id, escalation: escalation }
    )
    code
  end

  private

  def transition!(status, attributes)
    @service_assignment.transaction do
      request_status = attributes.delete(:service_request_status)
      @service_assignment.update!(attributes.merge(status: status))
      @service_assignment.service_request.update!(status: request_status)
    end
    AuditTrail.record!(
      action: "care_partner.visit_#{status}",
      actor: @actor,
      care_profile: @service_assignment.service_request.care_profile,
      metadata: { service_assignment_id: @service_assignment.id }
    )
    @service_assignment
  end
end
