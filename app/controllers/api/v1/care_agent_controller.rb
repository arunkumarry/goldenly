class Api::V1::CareAgentController < ActionController::API
  before_action :authenticate_user!

  def message
    message = params.require(:message).to_s
    action = CareActionPlanner.new(member: current_member, message: message).plan
    proposal = action&.merge("confirmation_token" => CareActionConfirmation.issue(member: current_member, action: action))

    render json: {
      reply: GoldenlyAssistant.new(message, member: current_member).reply,
      proposal: proposal,
      safety_note: "Goldenly provides coordination support, not medical advice. It cannot diagnose or change treatment."
    }
  end

  def confirm
    envelope = CareActionConfirmation.verify(params.require(:confirmation_token))
    return render json: { error: "This confirmation has expired. Please ask Goldenly again." }, status: :unprocessable_content unless envelope && envelope["member_id"] == current_member.id

    render json: CareActionExecutor.new(member: current_member, action: envelope.fetch("action"), share_location: params[:share_location]).confirm
  end

  private

  def authenticate_user!
    token = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
    payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256").first
    @current_user = User.find_by(id: payload["sub"])
    raise JWT::DecodeError unless @current_user && payload["type"] == "access"
  rescue JWT::DecodeError
    render json: { error: "Your session has expired. Please sign in again." }, status: :unauthorized
  end

  def current_member
    @current_member ||= @current_user.members.first || raise(ActiveRecord::RecordNotFound)
  end
end
