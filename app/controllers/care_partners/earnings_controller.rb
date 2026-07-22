class CarePartners::EarningsController < CarePartners::BaseController
  def index
    @entries = current_care_partner_account.earnings_ledger_entries.includes(service_assignment: { service_request: :service_catalog }).order(created_at: :desc)
    @totals = @entries.group_by(&:status).transform_values { |entries| entries.sum(&:net_payout_cents) }
  end
end
