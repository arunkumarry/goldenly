class Api::V1::RemindersController < ActionController::API
  include MobileCareProfileAuthentication

  def index
    return unless authorize_mobile_care_profile!(:appointments_routines, :view)

    render json: { reminders: current_mobile_care_profile.reminders.order(:scheduled_for).map { |reminder| reminder_payload(reminder) } }
  end

  def create
    return unless authorize_mobile_care_profile!(:appointments_routines, :manage)

    reminder = current_mobile_care_profile.reminders.create!(reminder_params)
    render json: { reminder: reminder_payload(reminder) }, status: :created
  end

  private

  def reminder_params
    params.permit(:title, :scheduled_for, :recurrence, :status)
  end

  def reminder_payload(reminder)
    reminder.slice(:id, :title, :scheduled_for, :recurrence, :status, :confirmed_at)
  end
end
