class CareNotificationDelivery
  def self.reminder(reminder)
    deliver(
      care_profile: reminder.care_profile,
      title: "Goldenly reminder",
      body: "It’s time for #{reminder.title}.",
      data: { type: "reminder", reminder_id: reminder.id, care_profile_id: reminder.care_profile_id }
    )
  end

  def self.service_request(service_request)
    deliver(
      care_profile: service_request.care_profile,
      title: "Goldenly service reminder",
      body: "#{service_request.service_type} is scheduled in 30 minutes.",
      data: { type: "service_request", service_request_id: service_request.id, care_profile_id: service_request.care_profile_id }
    )
  end

  def self.deliver(care_profile:, title:, body:, data:)
    recipient_ids = care_profile.care_profile_links.active.select(:user_id)
    tokens = DevicePushToken.active.where(user_id: recipient_ids).distinct
    ExpoPushNotification.deliver(tokens: tokens, title: title, body: body, data: data)
  end
  private_class_method :deliver
end
