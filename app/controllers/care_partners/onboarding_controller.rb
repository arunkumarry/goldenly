class CarePartners::OnboardingController < CarePartners::BaseController
  before_action :load_records

  def show
    @step = requested_step
  end

  def update
    @step = requested_step
    CarePartnerAccount.transaction do
      @profile.assign_attributes(profile_attributes)
      @account.assign_attributes(account_attributes)
      apply_declarations
      @profile.save!
      @account.save!
      @account.update!(onboarding_step: [ @step + 1, 4 ].min)
    end
    redirect_to care_partners_onboarding_path(step: [ @step + 1, 4 ].min), notice: "Draft saved. Continue when you are ready."
  rescue ActiveRecord::RecordInvalid
    render :show, status: :unprocessable_content
  end

  def submit
    CarePartnerApplicationSubmission.new(@account, actor: current_user).submit!
    redirect_to care_partners_root_path, notice: "Your application is with Goldenly’s human review team."
  rescue CarePartnerApplicationSubmission::IncompleteApplication => error
    redirect_to care_partners_onboarding_path(step: 4), alert: error.message
  end

  private

  def load_records
    @account = current_care_partner_account
    @profile = @account.profile
    @document = @account.verification_documents.new(country_code: @profile.country_code)
    @credential = @account.credentials.new
    @care_partner_service = @account.care_partner_services.new
  end

  def requested_step
    params.fetch(:step, @account.onboarding_step).to_i.clamp(1, 4)
  end

  def profile_attributes
    values = params.fetch(:care_partner_profile, {}).permit(
      :legal_name, :display_name, :date_of_birth, :profile_photo_url, :profile_photo, :address, :city, :region,
      :country, :country_code, :postal_code, :google_place_id, :latitude, :longitude,
      :experience_summary, :introduction_video_url, :emergency_contact_name, :emergency_contact_phone,
      :location_consent, :languages_text
    ).to_h
    values[:languages] = values.delete("languages_text").to_s.split(",").map(&:strip).reject(&:blank?) if values.key?("languages_text")
    values
  end

  def account_attributes
    params.fetch(:care_partner_account, {}).permit(:payout_method_summary).to_h
  end

  def apply_declarations
    declarations = params.fetch(:declarations, {}).permit(:terms, :privacy, :code_of_conduct, :service_standards)
    now = Time.current
    @account.terms_version = "2026-07" if declarations[:terms] == "1"
    @account.terms_accepted_at = now if declarations[:terms] == "1"
    @account.privacy_accepted_at = now if declarations[:privacy] == "1"
    @account.code_of_conduct_accepted_at = now if declarations[:code_of_conduct] == "1"
    @account.service_standards_accepted_at = now if declarations[:service_standards] == "1"
  end
end
