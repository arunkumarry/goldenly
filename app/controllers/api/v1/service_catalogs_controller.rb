class Api::V1::ServiceCatalogsController < ActionController::API
  include MobileCareProfileAuthentication

  def index
    return unless authorize_mobile_care_profile!(:service_requests, :view)

    render json: {
      service_catalogs: ServiceCatalog.available.map { |service| service.slice(:id, :kind, :name, :description) }
    }
  end
end
