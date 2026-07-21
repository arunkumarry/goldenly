class RemindersController < ApplicationController
  before_action -> { require_care_profile_permission!(:appointments_routines, :manage) }, only: %i[new create update]

  def new
    @reminder = current_care_profile.reminders.new(scheduled_for: Time.current.change(min: 0))
  end

  def create
    @reminder = current_care_profile.reminders.new(reminder_params)
    if @reminder.save
      redirect_to root_path, notice: "Reminder added to today’s plan."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    reminder = current_care_profile.reminders.find(params[:id])
    reminder.update!(status: params.require(:reminder).permit(:status).fetch(:status))
    AuditTrail.record!(action: "reminder.status_changed", actor: current_user, care_profile: current_care_profile, metadata: { reminder_id: reminder.id, status: reminder.status })
    respond_to do |format|
      format.turbo_stream { @reminder = reminder }
      format.html { redirect_to root_path, notice: "Reminder marked #{reminder.status}." }
    end
  end

  private

  def reminder_params
    params.require(:reminder).permit(:title, :scheduled_for, :recurrence)
  end
end
