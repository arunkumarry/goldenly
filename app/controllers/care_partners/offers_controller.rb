class CarePartners::OffersController < CarePartners::BaseController
  def index
    expire_stale_offers
    @offers = current_care_partner.service_offers.open.includes(service_request: :service_catalog).order(expires_at: :asc)
  end

  def accept
    offer = current_care_partner.service_offers.find(params[:id])
    assignment = CarePartnerMatching::OfferAcceptance.new(offer, actor: current_user).accept!
    redirect_to care_partners_assignment_path(assignment), notice: "Request accepted. The visit details are now available."
  rescue CarePartnerMatching::OfferAcceptance::NotAvailable => error
    redirect_to care_partners_offers_path, alert: error.message
  end

  def decline
    offer = current_care_partner.service_offers.find(params[:id])
    offer.update!(status: :declined, responded_at: Time.current)
    CarePartnerOfferBroadcast.remove(offer)
    redirect_to care_partners_offers_path, notice: "Request declined."
  end

  private

  def expire_stale_offers
    current_care_partner.service_offers.offered.where("expires_at <= ?", Time.current).update_all(status: "expired", responded_at: Time.current, updated_at: Time.current)
  end
end
