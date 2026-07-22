module CarePartnerMatching
  class OfferAcceptance
    class NotAvailable < StandardError; end

    def initialize(service_offer, actor:)
      @service_offer = service_offer
      @actor = actor
    end

    def accept!
      assignment = nil
      ServiceRequest.transaction do
        offer = ServiceOffer.lock.find(@service_offer.id)
        request = ServiceRequest.lock.find(offer.service_request_id)
        account = CarePartnerAccount.lock.find(offer.care_partner_account_id)

        raise NotAvailable, "This request has already been matched." if request.service_assignment.present? || !request.requested?
        raise NotAvailable, "This offer is no longer available." unless offer.open?
        unless account.eligible_for?(request.service_catalog, care_profile: request.care_profile, preferred_time: request.preferred_time)
          raise NotAvailable, "You are no longer eligible for this request."
        end

        assignment = request.create_service_assignment!(
          care_partner_account: account,
          status: :assigned,
          accepted_at: Time.current,
          contact_released: true
        )
        request.update!(
          status: :provider_assigned,
          assigned_provider_name: account.profile&.display_name || account.user.full_name,
          assigned_provider_phone: account.user.phone_number
        )
        offer.update!(status: :accepted, responded_at: Time.current)
        request.service_offers.where.not(id: offer.id).offered.update_all(status: "matched", responded_at: Time.current, updated_at: Time.current)
        create_ledger!(assignment)
      end

      AuditTrail.record!(
        action: "care_partner.request_accepted",
        actor: @actor,
        care_profile: assignment.service_request.care_profile,
        metadata: { service_request_id: assignment.service_request_id, service_assignment_id: assignment.id, care_partner_account_id: assignment.care_partner_account_id }
      )
      assignment
    end

    private

    def create_ledger!(assignment)
      catalog = assignment.service_request.service_catalog
      service_value = catalog.member_price_cents
      net_payout = catalog.partner_earning_cents
      assignment.create_earnings_ledger_entry!(
        care_partner_account: assignment.care_partner_account,
        currency: catalog.currency,
        service_value_cents: service_value,
        goldenly_fee_cents: [ service_value - net_payout, 0 ].max,
        net_payout_cents: net_payout,
        status: :estimated
      )
    end
  end
end
