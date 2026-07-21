class Api::V1::CareAgentController < ActionController::API
  include MobileCareProfileAuthentication

  def message
    message = params.require(:message).to_s
    care_profile = current_mobile_care_profile
    return unless care_profile

    conversation = conversation_for(care_profile)
    return if performed?

    action = CareActionPlanner.new(care_profile: care_profile, message: message, pending_service: conversation["pending_service"]).plan
    permission = action&.fetch("type") == "emergency_alert" ? :emergency_alerts : :appointments_routines
    return unless authorize_mobile_care_profile!(permission, :view, emergency: action&.fetch("type") == "emergency_alert")

    if action&.fetch("type") == "service_details_needed"
      reply = action.fetch("reply")
      return render json: {
        reply: reply,
        proposal: nil,
        conversation_token: next_conversation_token(care_profile, action.fetch("pending_service"), conversation, message, reply),
        safety_note: safety_note
      }
    end

    proposal = action&.merge("confirmation_token" => CareActionConfirmation.issue(care_profile: care_profile, action: action))
    reply = GoldenlyAssistant.new(message, care_profile: care_profile, history: conversation["history"]).reply

    render json: {
      reply: reply,
      proposal: proposal,
      conversation_token: proposal ? nil : next_conversation_token(care_profile, nil, conversation, message, reply),
      safety_note: safety_note
    }
  end

  def confirm
    envelope = CareActionConfirmation.verify(params.require(:confirmation_token))
    return render json: { error: "This confirmation has expired. Please ask Goldenly again." }, status: :unprocessable_content unless envelope && envelope["care_profile_id"] == current_mobile_care_profile.id

    permission = case envelope.dig("action", "type")
    when "service_request" then :service_requests
    when "emergency_alert" then :emergency_alerts
    else :appointments_routines
    end
    return unless authorize_mobile_care_profile!(permission, :manage, emergency: envelope.dig("action", "type") == "emergency_alert")

    render json: CareActionExecutor.new(care_profile: current_mobile_care_profile, action: envelope.fetch("action"), share_location: params[:share_location], actor: current_mobile_user).confirm
  end

  private

  def conversation_for(care_profile)
    return {} unless params[:conversation_token].present?

    envelope = CareAgentConversation.verify(params[:conversation_token])
    unless envelope && envelope["care_profile_id"] == care_profile.id
      render json: { error: "This scheduling conversation has expired. Please ask Goldenly again." }, status: :unprocessable_content
      return
    end

    envelope
  end

  def next_conversation_token(care_profile, pending_service, conversation, message, reply)
    history = Array(conversation["history"]) + [
      { "role" => "user", "content" => message },
      { "role" => "assistant", "content" => reply }
    ]

    CareAgentConversation.issue(care_profile: care_profile, pending_service: pending_service, history: history)
  end

  def safety_note
    "Goldenly provides coordination support, not medical advice. It cannot diagnose or change treatment."
  end
end
