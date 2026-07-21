class AssistantMessagesController < ApplicationController
  before_action -> { require_care_profile_permission!(:appointments_routines, :view) }, only: :create

  def create
    message = params.require(:message).to_s
    action = CareActionPlanner.new(care_profile: current_care_profile, message: message).plan
    session[:pending_care_action] = action&.merge("care_profile_id" => current_care_profile.id)

    render json: {
      reply: GoldenlyAssistant.new(message, care_profile: current_care_profile).reply,
      proposal: action,
      safety_note: "Goldenly provides coordination support, not medical advice. It cannot diagnose or change treatment."
    }
  end

  def confirm
    action = session.delete(:pending_care_action)
    return render json: { error: "There is no pending care action to confirm." }, status: :unprocessable_content unless action && action["care_profile_id"] == current_care_profile.id

    permission = case action["type"]
    when "service_request" then :service_requests
    when "emergency_alert" then :emergency_alerts
    else :appointments_routines
    end
    require_care_profile_permission!(permission, :manage, emergency: action["type"] == "emergency_alert")

    render json: CareActionExecutor.new(care_profile: current_care_profile, action: action, share_location: params[:share_location], actor: current_user).confirm
  end
end
