class Api::V1::ServiceRequestsController < ActionController::API
  def index
    render json: { service_requests: member.service_requests.order(created_at: :desc).map { |request| service_request_payload(request) } }
  end

  def create
    request = member.service_requests.create!(service_request_params)
    render json: { service_request: service_request_payload(request), message: "Please confirm before we dispatch a provider." }, status: :created
  end

  private

  def member
    Member.first || Member.create!(full_name: "New member", preferred_language: "English")
  end

  def service_request_params
    params.permit(:service_type, :notes, :preferred_time)
  end

  def service_request_payload(request)
    request.slice(:id, :service_type, :status, :preferred_time, :notes, :assigned_provider_name, :confirmed_at)
  end
end
