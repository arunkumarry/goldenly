class ServiceRequestsController < ApplicationController
  before_action -> { require_care_profile_permission!(:service_requests, :manage) }, only: %i[new create update]

  def new
    @service_request = current_care_profile.service_requests.new(service_catalog: ServiceCatalog.available.find_by(id: params[:service_catalog_id]))
  end

  def create
    @service_request = current_care_profile.service_requests.new(service_request_params)
    if @service_request.save
      redirect_to root_path, notice: "Service request saved. Confirm it before dispatching a provider."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    request = current_care_profile.service_requests.find(params[:id])
    request.update!(status: params.require(:service_request).permit(:status).fetch(:status), confirmed_at: Time.current)
    redirect_to root_path, notice: "Service request confirmed. We’ll arrange the provider next."
  end

  private

  def service_request_params
    params.require(:service_request).permit(:service_catalog_id, :preferred_time, :notes)
  end
end
