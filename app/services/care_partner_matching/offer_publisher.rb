module CarePartnerMatching
  class OfferPublisher
    OFFER_LIFETIME = 20.minutes

    def initialize(service_request, actor: nil)
      @service_request = service_request
      @actor = actor
    end

    def publish!
      return [] unless @service_request.requested?

      offers = eligible_partner_services.filter_map do |partner_service|
        care_partner = partner_service.care_partner
        next unless care_partner.eligible_for?(@service_request.service_catalog, care_profile: @service_request.care_profile, preferred_time: @service_request.preferred_time)

        offer = ServiceOffer.find_or_initialize_by(service_request: @service_request, care_partner: care_partner)
        next offer if offer.persisted? && offer.open?

        offer.assign_attributes(
          status: :offered,
          offered_at: Time.current,
          expires_at: OFFER_LIFETIME.from_now,
          responded_at: nil,
          eligibility_snapshot: minimal_snapshot(partner_service)
        )
        offer.save!
        CarePartnerOfferBroadcast.publish(offer)
        offer
      end

      @service_request.update_column(:offers_published_at, Time.current) if offers.any?
      AuditTrail.record!(
        action: "care_partner.offers_published",
        actor: @actor,
        care_profile: @service_request.care_profile,
        metadata: { service_request_id: @service_request.id, offer_count: offers.count }
      ) if offers.any? && @actor
      offers
    end

    private

    def eligible_partner_services
      CarePartnerService.active.includes(:service_catalog, care_partner: :profile)
        .where(service_catalog: @service_request.service_catalog)
    end

    def minimal_snapshot(partner_service)
      {
        service_name: @service_request.service_catalog.name,
        broad_location: [ @service_request.care_profile.city, @service_request.care_profile.region, @service_request.care_profile.country ].compact_blank.join(", "),
        requested_for: @service_request.preferred_time&.iso8601,
        preferred_language: @service_request.care_profile.preferred_language,
        estimated_earnings: @service_request.service_catalog.estimated_partner_earnings,
        service_mode: partner_service.service_modes
      }
    end
  end
end
