class Moderation::EarningsController < Moderation::BaseController
  before_action :require_payout_access!, only: :update

  def index
    @entries = EarningsLedgerEntry.includes(:care_partner, service_assignment: { service_request: :service_catalog }).order(created_at: :desc)
  end

  def update
    entry = EarningsLedgerEntry.find(params[:id])
    status = params.require(:earnings_ledger_entry).permit(:status).fetch(:status)
    unless %w[payout_processing paid failed on_hold].include?(status)
      return redirect_to moderation_earnings_path, alert: "Choose a valid manual payout status."
    end

    entry.update!(status: status, paid_at: status == "paid" ? Time.current : nil, payout_reference: params[:earnings_ledger_entry][:payout_reference])
    ModeratorReview.create!(care_partner: entry.care_partner, reviewer: current_user, decision: :payout_released, reason: "Manual payout marked #{status}.")
    AuditTrail.record!(action: "care_partner.payout_#{status}", actor: current_user, metadata: { earnings_ledger_entry_id: entry.id })
    redirect_to moderation_earnings_path, notice: "Manual payout status updated."
  end

  private

  def require_payout_access!
    return if current_user.can_manage_care_partner_payouts?

    redirect_to moderation_earnings_path, alert: "Finance or operations access is required for payouts."
  end
end
