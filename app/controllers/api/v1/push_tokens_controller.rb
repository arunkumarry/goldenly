class Api::V1::PushTokensController < ActionController::API
  include MobileCareProfileAuthentication

  def create
    token = current_mobile_user.device_push_tokens.find_or_initialize_by(token: push_token_params[:token])
    token.assign_attributes(platform: push_token_params[:platform], active: true, last_seen_at: Time.current)
    token.save!

    render json: { push_token: token.slice(:id, :platform, :active, :last_seen_at) }, status: :created
  end

  def destroy
    current_mobile_user.device_push_tokens.where(token: params.require(:token)).update_all(active: false, updated_at: Time.current)
    head :no_content
  end

  private

  def push_token_params
    params.permit(:token, :platform)
  end
end
