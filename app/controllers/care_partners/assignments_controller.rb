class CarePartners::AssignmentsController < CarePartners::BaseController
  before_action :load_assignment, only: %i[show check_in start submit_completion]

  def index
    @assignments = current_care_partner_account.service_assignments.includes(service_request: [ :service_catalog, :care_profile ]).order(updated_at: :desc)
  end

  def show; end

  def check_in
    CarePartnerVisitCompletion.new(@assignment, actor: current_user).check_in!
    redirect_to care_partners_assignment_path(@assignment), notice: "Check-in recorded."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_assignment_path(@assignment), alert: "This visit can no longer be checked in."
  end

  def start
    CarePartnerVisitCompletion.new(@assignment, actor: current_user).start!
    redirect_to care_partners_assignment_path(@assignment), notice: "Visit started."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_assignment_path(@assignment), alert: "This visit can no longer be started."
  end

  def submit_completion
    code = CarePartnerVisitCompletion.new(@assignment, actor: current_user).submit!(
      checklist: completion_params[:checklist].to_h,
      notes: completion_params[:notes],
      evidence: completion_params[:evidence].to_s.split("\n").map(&:strip).reject(&:blank?),
      follow_up_needed: completion_params[:follow_up_needed],
      escalation: completion_params[:escalation] == "1"
    )
    redirect_to care_partners_assignment_path(@assignment), notice: "Completion submitted. Ask the member to confirm in Goldenly. Confirmation reference ends in #{code.last(2)}."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_assignment_path(@assignment), alert: "Add the required visit details before submitting."
  end

  private

  def load_assignment
    @assignment = current_care_partner_account.service_assignments.includes(service_request: [ :service_catalog, :care_profile ]).find(params[:id])
  end

  def completion_params
    params.require(:visit_submission).permit(:notes, :evidence, :follow_up_needed, :escalation, checklist: {})
  end
end
