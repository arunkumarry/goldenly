class CarePartnerServiceEnrollment
  attr_reader :care_partner_service, :credential

  def self.credential_required_for?(service_catalog)
    service_catalog.requires_professional_credential? ||
      service_catalog.medical_health_checkup? ||
      service_catalog.diagnostic_service?
  end

  def initialize(care_partner:, service_attributes:, credential_attributes:)
    @care_partner = care_partner
    @service_attributes = service_attributes
    @credential_attributes = credential_attributes
  end

  def create!
    CarePartnerService.transaction(requires_new: true) do
        @care_partner.with_lock do
        @care_partner_service = @care_partner.care_partner_services.new(@service_attributes)
        @care_partner_service.save!
        save_credential! if self.class.credential_required_for?(@care_partner_service.service_catalog)
      end
    end

    @care_partner_service
  end

  def update!(care_partner_service)
    @care_partner_service = care_partner_service

    CarePartnerService.transaction(requires_new: true) do
      @care_partner_service.update!(@service_attributes)
      save_credential! if self.class.credential_required_for?(@care_partner_service.service_catalog)
    end

    @care_partner_service
  end

  private

  def save_credential!
    @credential = @care_partner.credentials.find_or_initialize_by(service_catalog: @care_partner_service.service_catalog)
    @credential.assign_attributes(@credential_attributes)
    @credential.errors.add(:credential_type, "is required for this service") if @credential.credential_type.blank?
    @credential.errors.add(:issuer, "is required for this service") if @credential.issuer.blank?
    raise ActiveRecord::RecordInvalid.new(@credential) if @credential.errors.any?

    @credential.save!
  end
end
