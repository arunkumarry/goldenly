class CarePartners::DashboardController < CarePartners::BaseController
  def index
    @profile = current_care_partner_account.profile
    @open_offers = current_care_partner_account.service_offers.open.includes(service_request: :service_catalog).order(expires_at: :asc).limit(4)
    @assignments = current_care_partner_account.service_assignments.includes(service_request: [ :service_catalog, :care_profile ]).where.not(status: %w[confirmed disputed cancelled]).order(updated_at: :desc).limit(4)
    @ledger_entries = current_care_partner_account.earnings_ledger_entries.order(created_at: :desc).limit(4)
    @completion_percentage = [ 100 - (current_care_partner_account.onboarding_missing_fields.count * 12), 0 ].max
  end

  def availability
    current_care_partner_account.update!(availability_status: params.require(:availability_status))
    redirect_to care_partners_root_path, notice: "You are now #{current_care_partner_account.availability_status}."
  end
end
