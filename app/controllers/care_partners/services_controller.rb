class CarePartners::ServicesController < CarePartners::BaseController
  def index
    @care_partner_services = current_care_partner_account.care_partner_services.includes(:service_catalog).order(created_at: :desc)
    @care_partner_service = current_care_partner_account.care_partner_services.new
  end

  def create
    service = current_care_partner_account.care_partner_services.new(service_attributes)
    service.save!
    redirect_to care_partners_services_path, notice: "Service preference saved. It will be activated after human review."
  rescue ActiveRecord::RecordInvalid
    @care_partner_services = current_care_partner_account.care_partner_services.includes(:service_catalog).order(created_at: :desc)
    @care_partner_service = service
    render :index, status: :unprocessable_content
  end

  def update
    service = current_care_partner_account.care_partner_services.find(params[:id])
    service.update!(service_attributes)
    redirect_to care_partners_services_path, notice: "Service preference updated."
  rescue ActiveRecord::RecordInvalid
    redirect_to care_partners_services_path, alert: service.errors.full_messages.to_sentence
  end

  def destroy
    current_care_partner_account.care_partner_services.find(params[:id]).destroy!
    redirect_to care_partners_services_path, notice: "Service preference removed."
  end

  private

  def service_attributes
    values = params.require(:care_partner_service).permit(
      :service_catalog_id, :travel_radius_km, :max_concurrent_visits, :service_zones_text,
      :languages_text, :service_modes_text, :available_days_text
    ).to_h
    values[:service_zones] = split_list(values.delete("service_zones_text"))
    values[:languages] = split_list(values.delete("languages_text"))
    values[:service_modes] = split_list(values.delete("service_modes_text")).presence || [ "in_person" ]
    days = split_list(values.delete("available_days_text"))
    values[:availability] = days.any? ? { "days" => days } : {}
    values
  end

  def split_list(value)
    value.to_s.split(",").map(&:strip).reject(&:blank?)
  end
end
