class CarePartners::OnboardingController < CarePartners::BaseController
  before_action :load_records

  def show
    @step = requested_step
    return if progress.allows?(@step)

    redirect_to care_partners_onboarding_path(step: progress.unlocked_step), alert: "Complete the current step before continuing."
  end

  def update
    @step = requested_step
    unless progress.allows?(@step)
      redirect_to care_partners_onboarding_path(step: progress.unlocked_step), alert: "Complete the current step before continuing."
      return
    end

    CarePartner.transaction do
      @profile.assign_attributes(profile_attributes)
      @account.assign_attributes(care_partner_attributes)
      apply_declarations
      @profile.save!
      @account.save!
      @account.activate_if_ready!
      progress.advance!
    end
    @unlocked_step = progress.unlocked_step
    if @unlocked_step > @step
      redirect_to care_partners_onboarding_path(step: @unlocked_step), notice: "Step #{@step} complete. Continue when you are ready."
    elsif progress.complete?(@step)
      redirect_to care_partners_onboarding_path(step: @step), notice: "Review details saved. Submit when you are ready."
    else
      redirect_to care_partners_onboarding_path(step: @step), alert: "Save the remaining details before continuing: #{progress.missing_fields_for(@step).to_sentence}."
    end
  rescue ActiveRecord::RecordInvalid
    @unlocked_step = progress.unlocked_step
    render :show, status: :unprocessable_content
  end

  def submit
    unless progress.allows?(4)
      redirect_to care_partners_onboarding_path(step: progress.unlocked_step), alert: "Complete the earlier onboarding steps before submitting."
      return
    end

    CarePartner.transaction do
      @account.assign_attributes(care_partner_attributes)
      apply_declarations
      @account.save!
      progress.advance!
      CarePartnerApplicationSubmission.new(@account, actor: current_user).submit!
    end
    redirect_to care_partners_root_path, notice: "Your application is with Goldenly’s human review team."
  rescue CarePartnerApplicationSubmission::IncompleteApplication => error
    redirect_to care_partners_onboarding_path(step: 4), alert: error.message
  rescue ActiveRecord::RecordInvalid => error
    redirect_to care_partners_onboarding_path(step: 4), alert: error.record.errors.full_messages.to_sentence
  end

  private

  def load_records
    @account = current_care_partner
    @profile = @account.profile
    @progress = CarePartnerOnboardingProgress.new(@account)
    @unlocked_step = @progress.unlocked_step
    # Build the form objects independently so they do not get mixed into the
    # persisted-record lists rendered on steps two and three.
    @document = CarePartnerVerificationDocument.new(care_partner_id: @account.id, country_code: @profile.country_code)
    @credential = CarePartnerCredential.new(care_partner_id: @account.id)
    @care_partner_service = CarePartnerService.new(care_partner_id: @account.id, max_concurrent_visits: 1)
  end

  def requested_step
    params.fetch(:step, @unlocked_step).to_i.clamp(1, 4)
  end

  def progress
    @progress
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

  def care_partner_attributes
    params.fetch(:care_partner, {}).permit(:payout_method_summary).to_h
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
