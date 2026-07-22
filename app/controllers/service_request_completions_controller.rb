class ServiceRequestCompletionsController < ApplicationController
  before_action -> { require_care_profile_permission!(:service_requests, :manage) }
  before_action :load_assignment

  def show; end

  def update
    confirmation = CarePartnerMemberConfirmation.new(@assignment, actor: current_user)
    if params.require(:completion).permit(:outcome, :code, :reason).fetch(:outcome) == "dispute"
      confirmation.dispute!(reason: params.dig(:completion, :reason))
      redirect_to dashboard_path, notice: "Thanks. Goldenly operations will review this service before any payout."
    else
      confirmation.confirm!(code: params.dig(:completion, :code))
      redirect_to dashboard_path, notice: "Service confirmed. Thank you for keeping the care record up to date."
    end
  rescue CarePartnerMemberConfirmation::InvalidConfirmation => error
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_content
  end

  private

  def load_assignment
    @service_request = current_care_profile.service_requests.find(params[:service_request_id])
    @assignment = @service_request.service_assignment
    raise ActiveRecord::RecordNotFound unless @assignment
  end
end
