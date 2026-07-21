class DashboardController < ApplicationController
  def index
    return redirect_to new_member_path if current_member.nil?

    load_dashboard
  end

  def timeline
    return redirect_to new_member_path if current_member.nil?

    load_dashboard
    render :index
  end

  def services
    return redirect_to new_member_path if current_member.nil?

    load_dashboard
    render :index
  end

  def circle
    return redirect_to new_member_path if current_member.nil?

    load_dashboard
    render :index
  end

  private

  def load_dashboard
    @care = DemoCareData.dashboard
    @member = current_member
    @reminders = @member.reminders.order(:scheduled_for).limit(4)
    @service_requests = @member.service_requests.order(created_at: :desc).limit(3)
    @contacts = @member.trusted_contacts.order(:name).limit(3)
  end
end
