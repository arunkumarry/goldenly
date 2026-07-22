class CarePartners::DocumentsController < CarePartners::BaseController
  def create
    document = current_care_partner_account.verification_documents.new(document_params)
    document.save!
    redirect_to care_partners_onboarding_path(step: 2), notice: "Identity document saved for human review."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_onboarding_path(step: 2), alert: document.errors.full_messages.to_sentence
  end

  def destroy
    current_care_partner_account.verification_documents.find(params[:id]).destroy!
    redirect_to care_partners_onboarding_path(step: 2), notice: "Document removed."
  end

  private

  def document_params
    params.require(:care_partner_verification_document).permit(:document_type, :country_code, :redacted_reference, :file_reference, :expires_on)
  end
end
