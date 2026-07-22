class Admin::ProvidersController < Admin::BaseController
  before_action :load_provider, only: %i[show update]

  def index
    @selected_status = params[:status].presence
    @provider_counts = CarePartner.group(:application_status).count
    @providers = CarePartner.includes(:user, :profile, care_partner_services: :service_catalog).order(submitted_at: :asc, created_at: :desc)
    @providers = @providers.where(application_status: @selected_status) if @selected_status && CarePartner.application_statuses.key?(@selected_status)
  end

  def show
    @reviews = @provider.moderator_reviews.includes(:reviewer).order(created_at: :desc)
  end

  def update
    CarePartnerModerationDecision.new(
      @provider,
      reviewer: current_admin_user,
      decision: review_params[:decision],
      reason: review_params[:reason],
      requested_sections: review_params[:requested_sections],
      ai_assistance: { "reviewed_by_human" => current_admin_user.full_name }
    ).apply!
    @provider.reload
    redirect_to admin_provider_path(@provider), notice: approval_message
  rescue CarePartnerModerationDecision::InvalidDecision, ActiveRecord::RecordInvalid => error
    @reviews = @provider.moderator_reviews.includes(:reviewer).order(created_at: :desc)
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_content
  end

  private

  def load_provider
    @provider = CarePartner.includes(:user, :profile, :verification_documents, :credentials, care_partner_services: :service_catalog).find(params[:id])
  end

  def review_params
    params.require(:moderator_review).permit(:decision, :reason, requested_sections: [])
  end

  def approval_message
    return "Care Partner approved and is ready to receive matching requests." if @provider.active_and_available?

    "Care Partner approval saved. Complete service or payout setup is still required before activation."
  end
end
