class CarePartners::ServicesController < CarePartners::BaseController
  before_action :ensure_services_step_available!

  def index
    @care_partner_services = current_care_partner.care_partner_services.includes(:service_catalog).order(created_at: :desc)
    @available_service_catalogs = ServiceCatalog.available.where.not(id: @care_partner_services.select(:service_catalog_id))
    @care_partner_service = current_care_partner.care_partner_services.new(max_concurrent_visits: 1)
  end

  def create
    CarePartnerServiceEnrollment.new(
      care_partner: current_care_partner,
      service_attributes: service_attributes,
      credential_attributes: credential_attributes
    ).create!
    current_care_partner.activate_if_ready!
    refresh_service_associations!
    redirect_to service_destination, notice: "Service added. It will be activated after human review."
  rescue ActiveRecord::RecordInvalid => error
    refresh_service_associations!
    redirect_to service_destination, alert: error.record.errors.full_messages.to_sentence
  end

  def update
    service = current_care_partner.care_partner_services.find(params[:id])
    CarePartnerServiceEnrollment.new(
      care_partner: current_care_partner,
      service_attributes: service_attributes,
      credential_attributes: credential_attributes
    ).update!(service)
    current_care_partner.activate_if_ready!
    refresh_service_associations!
    redirect_to service_destination, notice: "Service preference updated."
  rescue ActiveRecord::RecordInvalid => error
    refresh_service_associations!
    redirect_to service_destination, alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    service = current_care_partner.care_partner_services.find(params[:id])
    CarePartnerService.transaction do
      current_care_partner.credentials.where(service_catalog: service.service_catalog).destroy_all if CarePartnerServiceEnrollment.credential_required_for?(service.service_catalog)
      service.destroy!
    end
    refresh_service_associations!
    progression.advance!
    redirect_to service_destination, notice: "Service preference removed."
  end

  private

  def service_attributes
    values = params.require(:care_partner_service).permit(
      :service_catalog_id, :travel_radius_km, :max_concurrent_visits, :service_zones_text,
      :languages_text, :service_modes_text, :available_days_text,
      :coverage_place_id, :coverage_address, :coverage_city, :coverage_region,
      :coverage_country, :coverage_country_code, :coverage_latitude, :coverage_longitude,
      available_days: []
    ).to_h
    coverage_place = {
      "place_id" => values.delete("coverage_place_id"),
      "address" => values.delete("coverage_address"),
      "city" => values.delete("coverage_city"),
      "region" => values.delete("coverage_region"),
      "country" => values.delete("coverage_country"),
      "country_code" => values.delete("coverage_country_code"),
      "latitude" => values.delete("coverage_latitude"),
      "longitude" => values.delete("coverage_longitude")
    }.compact_blank
    service_zones_text = values.delete("service_zones_text")
    selected_zones = coverage_place.values_at("city", "region", "country", "country_code").compact_blank
    values[:service_zones] = selected_zones.presence || split_list(service_zones_text)
    values[:coverage_place] = coverage_place
    values[:languages] = split_list(values.delete("languages_text"))
    values[:service_modes] = split_list(values.delete("service_modes_text")).presence || [ "in_person" ]
    days = Array(values.delete("available_days")).map(&:strip).reject(&:blank?)
    days = split_list(values.delete("available_days_text")) if days.empty?
    values[:availability] = days.any? ? { "days" => days } : {}
    values
  end

  def credential_attributes
    params.fetch(:care_partner_credential, {}).permit(:credential_type, :issuer, :credential_reference, :expires_on).to_h
  end

  def split_list(value)
    value.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def progression
    @progression ||= CarePartnerOnboardingProgress.new(current_care_partner)
  end

  def ensure_services_step_available!
    return if progression.allows?(3)

    redirect_to care_partners_onboarding_path(step: progression.unlocked_step), alert: "Complete identity verification before choosing services."
  end

  def service_destination
    return care_partners_onboarding_path(step: 3) if params[:return_to_onboarding] == "1" || request.referer.to_s.include?(care_partners_onboarding_path)

    care_partners_services_path
  end

  def refresh_service_associations!
    current_care_partner.association(:care_partner_services).reset
    current_care_partner.association(:credentials).reset
  end
end
