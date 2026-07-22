class CarePartners::DocumentsController < CarePartners::BaseController
  before_action :ensure_identity_step_available!

  def create
    document = current_care_partner.verification_documents.new(document_params)
    document.save!
    progression.advance!
    redirect_to care_partners_onboarding_path(step: progression.unlocked_step), notice: "Identity document saved for human review."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_onboarding_path(step: 2), alert: document.errors.full_messages.to_sentence
  end

  def destroy
    current_care_partner.verification_documents.find(params[:id]).destroy!
    progression.advance!
    redirect_to care_partners_onboarding_path(step: progression.unlocked_step), notice: "Document removed."
  end

  private

  def document_params
    params.require(:care_partner_verification_document).permit(:document_type, :country_code, :redacted_reference, :file_reference, :expires_on, evidence_photos: [])
  end

  def progression
    @progression ||= CarePartnerOnboardingProgress.new(current_care_partner)
  end

  def ensure_identity_step_available!
    return if progression.allows?(2)

    redirect_to care_partners_onboarding_path(step: progression.unlocked_step), alert: "Complete your profile details before adding identity evidence."
  end
end
