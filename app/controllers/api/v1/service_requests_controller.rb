class Api::V1::ServiceRequestsController < ActionController::API
  include MobileCareProfileAuthentication

  def index
    return unless authorize_mobile_care_profile!(:service_requests, :view)

    render json: { service_requests: current_mobile_care_profile.service_requests.includes(:service_catalog, service_assignment: { care_partner: :profile }).order(created_at: :desc).map { |request| service_request_payload(request) } }
  end

  def create
    return unless authorize_mobile_care_profile!(:service_requests, :manage)

    attributes = service_request_params.to_h.symbolize_keys
    service_catalog = ServiceCatalog.available.find(attributes.delete(:service_catalog_id))
    request = current_mobile_care_profile.service_requests.create!(
      attributes.merge(
        service_catalog: service_catalog,
        status: :requested,
        confirmed_at: Time.current
      )
    )
    offers = CarePartnerMatching::OfferPublisher.new(request, actor: current_mobile_user).publish!
    render json: {
      service_request: service_request_payload(request),
      message: offers.any? ? "Your service request is confirmed. Eligible Care Partners have been notified." : "Your service request is confirmed. We are finding a suitable Care Partner."
    }, status: :created
  end

  private

  def service_request_params
    params.permit(:service_catalog_id, :notes, :preferred_time)
  end

  def service_request_payload(request)
    request.slice(:id, :service_type, :status, :preferred_time, :notes, :assigned_provider_name, :confirmed_at).merge(
      service_catalog_id: request.service_catalog_id,
      service_kind: request.service_catalog.kind,
      service_name: request.service_catalog.name,
      assigned_provider: assigned_provider_payload(request)
    )
  end

  def assigned_provider_payload(request)
    care_partner = request.service_assignment&.care_partner
    return unless care_partner

    profile = care_partner.profile
    {
      id: care_partner.id,
      name: profile&.display_name.presence || care_partner.user.full_name,
      phone_number: care_partner.user.phone_number,
      email_address: care_partner.user.email_address,
      location: profile&.broad_location
    }
  end
end
