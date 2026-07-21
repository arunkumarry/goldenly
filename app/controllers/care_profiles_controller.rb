class CareProfilesController < ApplicationController
  before_action :set_care_profile, only: %i[edit update]

  def new
    @care_profile = CareProfile.new(preferred_language: "English", country: current_user.country, state: "unclaimed")
  end

  def create
    @care_profile = build_care_profile
    if @care_profile
      session[:care_profile_id] = @care_profile.id
      redirect_to dashboard_path, notice: "#{@care_profile.full_name}'s care profile is ready."
    else
      @care_profile = CareProfile.new(care_profile_params)
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid => error
    @care_profile = error.record
    render :new, status: :unprocessable_content
  end

  def edit
    authorize_profile_management!
  end

  def update
    authorize_profile_management!
    if @care_profile.update(care_profile_params)
      AuditTrail.record!(action: "care_profile.updated", actor: current_user, care_profile: @care_profile)
      redirect_to dashboard_path, notice: "Care profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_care_profile
    @care_profile = current_care_profile
    raise ActiveRecord::RecordNotFound unless @care_profile
  end

  def build_care_profile
    onboarding = CareProfileOnboarding.new(account_user: current_user)
    if params[:setup_for] == "self"
      onboarding.create_self!(care_profile_params)
    else
      onboarding.create_for_someone_else!(
        care_profile_params,
        relationship: params[:relationship_to_person].presence || "family",
        consent_basis: params[:consent_basis].presence || "coordinator confirmed initial setup",
        state: params[:care_profile][:state].presence_in(%w[unclaimed assisted]) || "unclaimed"
      )
    end
  end

  def authorize_profile_management!
    return if @care_profile.owned_by?(current_user)

    require_care_profile_permission!(:appointments_routines, :manage)
  end

  def care_profile_params
    params.require(:care_profile).permit(:full_name, :phone_number, :preferred_language, :mobility_needs, :emergency_contact_name, :emergency_contact_phone, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id, accessibility_preferences: %i[text_size high_contrast voice_guidance])
  end
end
