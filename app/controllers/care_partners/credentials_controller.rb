class CarePartners::CredentialsController < CarePartners::BaseController
  def create
    credential = current_care_partner_account.credentials.new(credential_params)
    credential.save!
    redirect_to care_partners_onboarding_path(step: 3), notice: "Credential saved for human review."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_onboarding_path(step: 3), alert: credential.errors.full_messages.to_sentence
  end

  def destroy
    current_care_partner_account.credentials.find(params[:id]).destroy!
    redirect_to care_partners_onboarding_path(step: 3), notice: "Credential removed."
  end

  private

  def credential_params
    params.require(:care_partner_credential).permit(:service_catalog_id, :credential_type, :issuer, :credential_reference, :file_reference, :issued_on, :expires_on)
  end
end
