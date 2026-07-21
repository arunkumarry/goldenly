class Api::V1::RemindersController < ActionController::API
  def index
    render json: { reminders: member.reminders.order(:scheduled_for).map { |reminder| reminder_payload(reminder) } }
  end

  def create
    reminder = member.reminders.create!(reminder_params)
    render json: { reminder: reminder_payload(reminder) }, status: :created
  end

  private

  def member
    Member.first || Member.create!(full_name: "New member", preferred_language: "English")
  end

  def reminder_params
    params.permit(:title, :scheduled_for, :recurrence, :status)
  end

  def reminder_payload(reminder)
    reminder.slice(:id, :title, :scheduled_for, :recurrence, :status, :confirmed_at)
  end
end
