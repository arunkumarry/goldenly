class Reminder < ApplicationRecord
  include BelongsToCareProfile

  validates :title, :scheduled_for, presence: true

  after_commit :schedule_notification, on: %i[create update], if: :saved_change_to_scheduled_for?

  def due?
    status != "completed" && scheduled_for <= Time.current
  end

  private

  def schedule_notification
    return unless status == "pending" && scheduled_for.future?

    CareReminderNotificationJob.set(wait_until: scheduled_for).perform_later(id, scheduled_for.to_i)
  end
end
