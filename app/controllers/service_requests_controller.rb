class ServiceRequestsController < ApplicationController
  before_action -> { require_care_profile_permission!(:service_requests, :manage) }, only: %i[new create update]

  def new
    @service_request = current_care_profile.service_requests.new(service_catalog: ServiceCatalog.available.find_by(id: params[:service_catalog_id]), preferred_time: Time.current.change(min: 0) + 1.hour)
  end

  def create
    @service_request = current_care_profile.service_requests.new(service_request_params)
    if @service_request.save
      redirect_to dashboard_path, notice: "Service request saved. Confirm it before dispatching a provider."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    request = current_care_profile.service_requests.find(params[:id])
    return redirect_to(dashboard_path, alert: "Only saved requests can be confirmed.") unless request.awaiting_confirmation?

    request.update!(status: :requested, confirmed_at: Time.current)
    offers = CarePartnerMatching::OfferPublisher.new(request, actor: current_user).publish!
    message = offers.any? ? "Service request confirmed. Eligible Care Partners have been notified." : "Service request confirmed. We are finding a suitable Care Partner."
    redirect_to dashboard_path, notice: message
  end

  private

  def service_request_params
    attributes = params.require(:service_request).permit(:service_catalog_id, :notes)
    attributes[:preferred_time] = selected_date_and_hour if params[:preferred_date].present? && params[:preferred_hour].present?
    attributes
  end

  def selected_date_and_hour
    date = Date.iso8601(params.require(:preferred_date))
    hour = Integer(params.require(:preferred_hour))
    raise ArgumentError unless hour.between?(0, 23)

    Time.zone.local(date.year, date.month, date.day, hour)
  rescue Date::Error, ArgumentError
    nil
  end
end
