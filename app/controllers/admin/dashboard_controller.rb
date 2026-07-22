class Admin::DashboardController < Admin::BaseController
  def index
    @member_count = member_records.count
    @provider_counts = CarePartner.group(:application_status).count
    @review_queue = CarePartner.includes(:user, :profile)
      .where(application_status: %w[submitted under_review changes_requested])
      .order(submitted_at: :asc, created_at: :asc)
      .limit(8)
    @recent_members = member_records.includes(:owned_care_profiles).order(created_at: :desc).limit(6)
  end
end
