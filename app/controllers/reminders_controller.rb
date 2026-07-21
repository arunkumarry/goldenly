class RemindersController < ApplicationController
  before_action -> { require_care_profile_permission!(:appointments_routines, :manage) }, only: %i[new create update]

  def new
    @reminder = current_care_profile.reminders.new(scheduled_for: Time.current.change(min: 0) + 1.hour)
  end

  def create
    @reminder = current_care_profile.reminders.new(reminder_params)
    if @reminder.save
      redirect_to dashboard_path, notice: "Reminder added to today’s plan."
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def update
    reminder = current_care_profile.reminders.find(params[:id])
    reminder.update!(status: params.require(:reminder).permit(:status).fetch(:status))
    AuditTrail.record!(action: "reminder.status_changed", actor: current_user, care_profile: current_care_profile, metadata: { reminder_id: reminder.id, status: reminder.status })
    respond_to do |format|
      format.turbo_stream { @reminder = reminder }
      format.html { redirect_to dashboard_path, notice: "Reminder marked #{reminder.status}." }
    end
  end

  private

  def reminder_params
    attributes = params.require(:reminder).permit(:title, :recurrence)
    attributes[:scheduled_for] = selected_date_and_hour
    attributes
  end

  def selected_date_and_hour
    date = Date.iso8601(params.require(:scheduled_date))
    hour = Integer(params.require(:scheduled_hour))
    raise ArgumentError unless hour.between?(0, 23)

    Time.zone.local(date.year, date.month, date.day, hour)
  rescue Date::Error, ArgumentError
    @reminder ||= current_care_profile.reminders.new
    @reminder.errors.add(:scheduled_for, "must include a valid date and hour")
    raise ActiveRecord::RecordInvalid, @reminder
  end
end
