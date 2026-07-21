class CareActionExecutor
  def initialize(care_profile:, action:, share_location: false, actor: nil)
    @care_profile = care_profile
    @action = action
    @share_location = ActiveModel::Type::Boolean.new.cast(share_location)
    @actor = actor
  end

  def confirm
    case @action.fetch("type")
    when "reminder" then confirm_reminder
    when "service_request" then confirm_service_request
    when "emergency_alert" then confirm_emergency_alert
    else raise ArgumentError, "Unsupported care action"
    end
  end

  private

  def confirm_reminder
    reminder = @care_profile.reminders.create!(title: @action.fetch("reminder_title"), scheduled_for: @action.fetch("scheduled_for"), created_by_ai: true, confirmed_at: Time.current)
    AuditTrail.record!(action: "reminder.created_by_assistant", actor: @actor, care_profile: @care_profile, metadata: { reminder_id: reminder.id })
    { message: "Reminder saved for #{reminder.scheduled_for.strftime('%-I:%M %p on %-d %b')}.", record_type: "reminder", record_id: reminder.id }
  end

  def confirm_service_request
    service_catalog = ServiceCatalog.for_service_type(@action.fetch("service_type"))
    request = @care_profile.service_requests.create!(
      service_catalog: service_catalog,
      notes: @action["notes"],
      preferred_time: @action["preferred_time"],
      status: "requested",
      confirmed_at: Time.current
    )
    AuditTrail.record!(action: "service_request.created_by_assistant", actor: @actor, care_profile: @care_profile, metadata: { service_request_id: request.id })
    time_note = request.preferred_time ? " Your preferred time is #{request.preferred_time.strftime('%-I:%M %p on %-d %b')}." : ""
    { message: "Your #{request.service_type.downcase} request is confirmed. Provider matching is the next phase.#{time_note}", record_type: "service_request", record_id: request.id }
  end

  def confirm_emergency_alert
    number = @action.fetch("emergency_number")
    alert = @care_profile.emergency_alerts.create!(
      status: "confirmed", message: @action["message"], share_location: @share_location,
      location: @care_profile.location, country: @care_profile.country, emergency_number: number,
      trusted_contact_count: @care_profile.trusted_contacts.count, confirmed_at: Time.current
    )
    AuditTrail.record!(action: "sos.confirmed", actor: @actor, care_profile: @care_profile, metadata: { emergency_alert_id: alert.id, location_shared: @share_location })
    {
      message: "Emergency alert recorded for #{alert.trusted_contact_count} trusted contact(s). Call #{number} for immediate emergency help.",
      record_type: "emergency_alert", record_id: alert.id, emergency_call_url: "tel:#{number}"
    }
  end
end
