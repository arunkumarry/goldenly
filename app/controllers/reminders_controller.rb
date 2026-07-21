class RemindersController < ApplicationController
  def new
    @reminder = current_member.reminders.new(scheduled_for: Time.current.change(min: 0))
  end

  def create
    @reminder = current_member.reminders.new(reminder_params)
    if @reminder.save
      redirect_to root_path, notice: "Reminder added to today’s plan."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    reminder = current_member.reminders.find(params[:id])
    reminder.update!(status: params.require(:reminder).permit(:status).fetch(:status))
    redirect_to root_path, notice: "Reminder marked #{reminder.status}."
  end

  private

  def reminder_params
    params.require(:reminder).permit(:title, :scheduled_for, :recurrence)
  end
end
