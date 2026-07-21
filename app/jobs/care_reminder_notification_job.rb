class CareReminderNotificationJob < ApplicationJob
  def perform(reminder_id, scheduled_for_epoch)
    reminder = Reminder.find_by(id: reminder_id)
    return unless reminder&.status == "pending"
    return unless reminder.scheduled_for.to_i == scheduled_for_epoch

    CareNotificationDelivery.reminder(reminder)
  end
end
