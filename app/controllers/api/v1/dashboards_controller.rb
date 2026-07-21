class Api::V1::DashboardsController < ActionController::API
  def show
    member = Member.first
    return render json: { error: "No member has been set up" }, status: :not_found unless member

    render json: {
      member: member.slice(:id, :full_name, :preferred_language, :mobility_needs),
      reminders: member.reminders.order(:scheduled_for).map { |reminder| reminder_payload(reminder) },
      service_requests: member.service_requests.order(created_at: :desc).map { |request| service_request_payload(request) }
    }
  end

  private

  def reminder_payload(reminder)
    reminder.slice(:id, :title, :scheduled_for, :recurrence, :status, :confirmed_at)
  end

  def service_request_payload(request)
    request.slice(:id, :service_type, :status, :preferred_time, :notes, :assigned_provider_name, :confirmed_at)
  end
end
