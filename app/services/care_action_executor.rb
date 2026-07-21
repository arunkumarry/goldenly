class CareActionExecutor
  def initialize(member:, action:, share_location: false)
    @member = member
    @action = action
    @share_location = ActiveModel::Type::Boolean.new.cast(share_location)
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
    reminder = @member.reminders.create!(title: @action.fetch("reminder_title"), scheduled_for: @action.fetch("scheduled_for"), created_by_ai: true, confirmed_at: Time.current)
    { message: "Reminder saved for #{reminder.scheduled_for.strftime('%-I:%M %p on %-d %b')}.", record_type: "reminder", record_id: reminder.id }
  end

  def confirm_service_request
    request = @member.service_requests.create!(
      service_type: @action.fetch("service_type"),
      notes: @action["notes"],
      preferred_time: @action["preferred_time"],
      status: "requested",
      confirmed_at: Time.current
    )
    time_note = request.preferred_time ? " Your preferred time is #{request.preferred_time.strftime('%-I:%M %p on %-d %b')}." : ""
    { message: "Your #{request.service_type.downcase} request is confirmed. Provider matching is the next phase.#{time_note}", record_type: "service_request", record_id: request.id }
  end

  def confirm_emergency_alert
    number = @action.fetch("emergency_number")
    alert = @member.emergency_alerts.create!(
      status: "confirmed", message: @action["message"], share_location: @share_location,
      location: @member.location, country: @member.country, emergency_number: number,
      trusted_contact_count: @member.trusted_contacts.count, confirmed_at: Time.current
    )
    {
      message: "Emergency alert recorded for #{alert.trusted_contact_count} trusted contact(s). Call #{number} for immediate emergency help.",
      record_type: "emergency_alert", record_id: alert.id, emergency_call_url: "tel:#{number}"
    }
  end
end
