class Api::V1::CareProfilesController < ActionController::API
  include MobileCareProfileAuthentication

  def index
    render json: { care_profiles: current_mobile_user.active_care_profile_links.map { |link| care_profile_payload(link) } }
  end

  def create
    setup_for = params[:setup_for].presence || "self"
    onboarding = CareProfileOnboarding.new(account_user: current_mobile_user, source: "mobile")
    care_profile = if setup_for == "someone_else"
      onboarding.create_for_someone_else!(care_profile_params, relationship: params[:relationship_to_person].presence || "family", consent_basis: params[:consent_basis].presence || "coordinator confirmed initial setup", state: params[:state].presence_in(%w[unclaimed assisted]) || "unclaimed")
    else
      onboarding.create_self!(care_profile_params)
    end
    render json: { care_profile: care_profile_payload(current_mobile_user.care_profile_link_for(care_profile)) }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content
  end

  private

  def care_profile_params
    params.require(:care_profile).permit(:full_name, :phone_number, :preferred_language, :country, :location, :mobility_needs, accessibility_preferences: %i[text_size high_contrast voice_guidance])
  end

  def care_profile_payload(link)
    link.care_profile.slice(:id, :full_name, :state, :preferred_language, :country, :location).merge("relationship_to_person" => link.relationship_to_person, "permissions" => link.permissions)
  end
end
