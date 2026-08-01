class SosAlertDispatcher
  def initialize(emergency_alert:, actor: nil)
    @emergency_alert = emergency_alert
    @actor = actor
  end

  def deliver!
    recipients.each { |recipient| deliver_to(recipient) }
  end

  private

  def recipients
    linked = @emergency_alert.care_profile.care_profile_links.active.includes(:user).filter_map do |link|
      next unless link.allows?(:emergency_alerts, :view, emergency: true)
      next if @actor && link.user_id == @actor.id

      { user: link.user, name: link.user.full_name, phone_number: link.user.phone_number }
    end
    legacy = @emergency_alert.care_profile.trusted_contacts.filter_map do |contact|
      next unless contact.phone_number.present? || contact.email.present?

      { user: nil, name: contact.name, phone_number: contact.phone_number }
    end
    (linked + legacy).uniq { |recipient| [ recipient[:user]&.id, recipient[:phone_number], recipient[:name] ] }
  end

  def deliver_to(recipient)
    message = message_for(recipient)
    deliver_push(recipient, message)
    deliver_sms(recipient, message)
  end

  def deliver_push(recipient, message)
    return record(recipient, "push", "skipped", reason: "No Goldenly account is linked.") unless recipient[:user]

    tokens = recipient[:user].device_push_tokens.active
    return record(recipient, "push", "skipped", reason: "No active device token.") if tokens.none?

    result = ExpoPushNotification.deliver(tokens:, title: "Goldenly SOS alert", body: message, data: { type: "sos", emergency_alert_id: @emergency_alert.id, care_profile_id: @emergency_alert.care_profile_id })
    record(recipient, "push", result.fetch(:status), result)
  end

  def deliver_sms(recipient, message)
    return record(recipient, "sms", "skipped", reason: "No phone number is recorded.") if recipient[:phone_number].blank?

    result = TwilioMessaging.deliver_sms(to: recipient[:phone_number], body: message)
    record(recipient, "sms", result.fetch(:status), result)
  end

  def record(recipient, channel, status, metadata = {})
    @emergency_alert.sos_alert_deliveries.create!(
      recipient_user: recipient[:user], recipient_label: recipient[:name], channel:, status:,
      consent_basis: "confirmed_sos_alert", location_shared: @emergency_alert.share_location,
      metadata: metadata.slice(:reason, :provider_message_id), delivered_at: status == "delivered" ? Time.current : nil
    )
  end

  def message_for(recipient)
    profile = @emergency_alert.care_profile
    location = @emergency_alert.share_location && @emergency_alert.location.present? ? " Location: #{@emergency_alert.location}." : ""
    "Goldenly SOS: #{profile.full_name} requested emergency help.#{location} Call #{profile.full_name} or local emergency services if needed."
  end
end
