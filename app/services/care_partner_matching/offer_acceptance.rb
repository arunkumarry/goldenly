module CarePartnerMatching
  class OfferAcceptance
    class NotAvailable < StandardError; end

    def initialize(service_offer, actor:)
      @service_offer = service_offer
      @actor = actor
    end

    def accept!
      assignment = nil
      accepted_offer = nil
      unavailable_offers = []
      ServiceRequest.transaction do
        offer = ServiceOffer.lock.find(@service_offer.id)
        request = ServiceRequest.lock.find(offer.service_request_id)
        care_partner = CarePartner.lock.find(offer.care_partner_id)

        raise NotAvailable, "This request has already been matched." if request.service_assignment.present? || !request.requested?
        raise NotAvailable, "This offer is no longer available." unless offer.open?
        unless care_partner.eligible_for?(request.service_catalog, care_profile: request.care_profile, preferred_time: request.preferred_time)
          raise NotAvailable, "You are no longer eligible for this request."
        end

        assignment = request.create_service_assignment!(
          care_partner: care_partner,
          status: :assigned,
          accepted_at: Time.current,
          contact_released: true
        )
        request.update!(
          status: :provider_assigned,
          assigned_provider_name: care_partner.profile&.display_name || care_partner.user.full_name,
          assigned_provider_phone: care_partner.user.phone_number
        )
        offer.update!(status: :accepted, responded_at: Time.current)
        unavailable_offers = request.service_offers.where.not(id: offer.id).offered.lock.to_a
        unavailable_offers.each { |other_offer| other_offer.update!(status: :matched, responded_at: Time.current) }
        accepted_offer = offer
        create_ledger!(assignment)
      end

      CarePartnerOfferBroadcast.remove(accepted_offer)
      unavailable_offers.each { |offer| CarePartnerOfferBroadcast.remove(offer) }

      AuditTrail.record!(
        action: "care_partner.request_accepted",
        actor: @actor,
        care_profile: assignment.service_request.care_profile,
        metadata: { service_request_id: assignment.service_request_id, service_assignment_id: assignment.id, care_partner_id: assignment.care_partner_id }
      )
      assignment
    end

    private

    def create_ledger!(assignment)
      catalog = assignment.service_request.service_catalog
      service_value = catalog.member_price_cents
      net_payout = catalog.partner_earning_cents
      assignment.create_earnings_ledger_entry!(
        care_partner: assignment.care_partner,
        currency: catalog.currency,
        service_value_cents: service_value,
        goldenly_fee_cents: [ service_value - net_payout, 0 ].max,
        net_payout_cents: net_payout,
        status: :estimated
      )
    end
  end
end
