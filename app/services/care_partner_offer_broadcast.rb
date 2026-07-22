class CarePartnerOfferBroadcast
  def self.publish(offer)
    offer = offer.reload
    Turbo::StreamsChannel.broadcast_prepend_to(
      [ offer.care_partner, :open_offers ],
      target: "open-offers",
      partial: "care_partners/offers/offer",
      locals: { offer: offer }
    )
    Turbo::StreamsChannel.broadcast_append_to(
      [ offer.care_partner, :offer_notifications ],
      target: "offer-notifications",
      partial: "care_partners/offers/notification",
      locals: { offer: offer }
    )
  end

  def self.remove(offer)
    Turbo::StreamsChannel.broadcast_remove_to(
      [ offer.care_partner, :open_offers ],
      target: ActionView::RecordIdentifier.dom_id(offer)
    )
  end
end
