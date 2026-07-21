class ServiceRequestsController < ApplicationController
  def new
    @service_request = current_member.service_requests.new(service_type: params[:service_type])
  end

  def create
    @service_request = current_member.service_requests.new(service_request_params)
    if @service_request.save
      redirect_to root_path, notice: "Service request saved. Confirm it before dispatching a provider."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    request = current_member.service_requests.find(params[:id])
    request.update!(status: params.require(:service_request).permit(:status).fetch(:status), confirmed_at: Time.current)
    redirect_to root_path, notice: "Service request confirmed. We’ll arrange the provider next."
  end

  private

  def service_request_params
    params.require(:service_request).permit(:service_type, :preferred_time, :notes)
  end
end
