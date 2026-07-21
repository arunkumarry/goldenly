class Api::V1::DashboardsController < ActionController::API
  include MobileCareProfileAuthentication

  def show
    return unless authorize_mobile_care_profile!(:appointments_routines, :view)

    care_profile = current_mobile_care_profile

    render json: {
      care_profile: care_profile.slice(:id, :full_name, :preferred_language, :mobility_needs, :state, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id),
      care_profiles: current_mobile_user.active_care_profile_links.map { |link| link.care_profile.slice(:id, :full_name, :state).merge("relationship_to_person" => link.relationship_to_person) },
      reminders: care_profile.reminders.order(:scheduled_for).map { |reminder| reminder_payload(reminder) },
      service_catalogs: ServiceCatalog.available.map { |service| service_catalog_payload(service) },
      service_requests: care_profile.service_requests.includes(:service_catalog).order(created_at: :desc).map { |request| service_request_payload(request) },
      trusted_circle: care_profile.care_profile_links.active.includes(:user).where.not(user: current_mobile_user).map { |link| { id: link.id, name: link.user.full_name, relationship: link.relationship_to_person, permissions: link.permissions } }
    }
  end

  private

  def reminder_payload(reminder)
    reminder.slice(:id, :title, :scheduled_for, :recurrence, :status, :confirmed_at)
  end

  def service_request_payload(request)
    request.slice(:id, :service_type, :status, :preferred_time, :notes, :assigned_provider_name, :confirmed_at).merge(
      service_catalog_id: request.service_catalog_id,
      service_kind: request.service_catalog.kind,
      service_name: request.service_catalog.name
    )
  end

  def service_catalog_payload(service)
    service.slice(:id, :kind, :name, :description)
  end
end
