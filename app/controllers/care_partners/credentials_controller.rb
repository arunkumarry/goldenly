class CarePartners::CredentialsController < CarePartners::BaseController
  before_action :ensure_services_step_available!

  def create
    credential = current_care_partner.credentials.new(credential_params)
    credential.save!
    progression.advance!
    redirect_to care_partners_onboarding_path(step: 3), notice: "Credential saved for human review."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_onboarding_path(step: 3), alert: credential.errors.full_messages.to_sentence
  end

  def destroy
    current_care_partner.credentials.find(params[:id]).destroy!
    progression.advance!
    redirect_to care_partners_onboarding_path(step: 3), notice: "Credential removed."
  end

  private

  def credential_params
    params.require(:care_partner_credential).permit(:service_catalog_id, :credential_type, :issuer, :credential_reference, :file_reference, :issued_on, :expires_on)
  end

  def progression
    @progression ||= CarePartnerOnboardingProgress.new(current_care_partner)
  end

  def ensure_services_step_available!
    return if progression.allows?(3)

    redirect_to care_partners_onboarding_path(step: progression.unlocked_step), alert: "Complete identity verification before adding credentials."
  end
end
