class Moderation::CarePartnerApplicationsController < Moderation::BaseController
  before_action :load_account, only: %i[show update]

  def index
    @applications = CarePartnerAccount.includes(:user, :profile).where(application_status: %w[submitted under_review changes_requested approved]).order(submitted_at: :asc)
  end

  def show
    @reviews = @account.moderator_reviews.includes(:reviewer).order(created_at: :desc)
  end

  def update
    update_evidence_statuses
    CarePartnerModerationDecision.new(
      @account,
      reviewer: current_user,
      decision: review_params[:decision],
      reason: review_params[:reason],
      requested_sections: review_params[:requested_sections],
      ai_assistance: { "reviewed_by_human" => current_user.full_name }
    ).apply!
    redirect_to moderation_care_partner_application_path(@account), notice: "Human review decision saved."
  rescue CarePartnerModerationDecision::InvalidDecision, ActiveRecord::RecordInvalid => error
    @reviews = @account.moderator_reviews.includes(:reviewer).order(created_at: :desc)
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_content
  end

  private

  def load_account
    @account = CarePartnerAccount.includes(:user, :profile, :verification_documents, :credentials, care_partner_services: :service_catalog).find(params[:id])
  end

  def update_evidence_statuses
    safely_update_statuses(@account.verification_documents, params[:document_statuses])
    safely_update_statuses(@account.credentials, params[:credential_statuses])
  end

  def safely_update_statuses(scope, statuses)
    return if statuses.blank?

    statuses.to_unsafe_h.each do |id, status|
      next unless %w[pending approved changes_requested rejected].include?(status)

      scope.find_by(id: id)&.update!(verification_status: status)
    end
  end

  def review_params
    params.require(:moderator_review).permit(:decision, :reason, requested_sections: [])
  end
end
