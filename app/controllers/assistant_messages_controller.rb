class AssistantMessagesController < ApplicationController
  def create
    message = params.require(:message).to_s
    action = CareActionPlanner.new(member: current_member, message: message).plan
    session[:pending_care_action] = action&.merge("member_id" => current_member.id)

    render json: {
      reply: GoldenlyAssistant.new(message, member: current_member).reply,
      proposal: action,
      safety_note: "Goldenly provides coordination support, not medical advice. It cannot diagnose or change treatment."
    }
  end

  def confirm
    action = session.delete(:pending_care_action)
    return render json: { error: "There is no pending care action to confirm." }, status: :unprocessable_content unless action && action["member_id"] == current_member.id

    render json: CareActionExecutor.new(member: current_member, action: action, share_location: params[:share_location]).confirm
  end
end
