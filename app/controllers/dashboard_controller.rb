class DashboardController < ApplicationController
  def index
    return redirect_to new_care_profile_path if current_care_profile.nil?

    load_dashboard
  end

  def timeline
    return redirect_to new_care_profile_path if current_care_profile.nil?

    load_dashboard
    render :index
  end

  def calendar
    return redirect_to new_care_profile_path if current_care_profile.nil?

    require_care_profile_permission!(:appointments_routines, :view)
    @care_profile = current_care_profile
    @calendar_month = parse_calendar_month
    range = @calendar_month.beginning_of_month.beginning_of_week..@calendar_month.end_of_month.end_of_week
    @calendar_events = @care_profile.reminders.where(scheduled_for: range).order(:scheduled_for).group_by { |reminder| reminder.scheduled_for.to_date }
    @service_events = @care_profile.service_requests.where(preferred_time: range).order(:preferred_time).group_by { |request| request.preferred_time.to_date }
  end

  def services
    return redirect_to new_care_profile_path if current_care_profile.nil?

    load_dashboard
    render :index
  end

  def circle
    return redirect_to new_care_profile_path if current_care_profile.nil?

    load_dashboard
    render :index
  end

  private

  def load_dashboard
    @care_profile = current_care_profile
    @reminders = @care_profile.reminders.order(:scheduled_for).limit(4)
    @today_reminders = @care_profile.reminders.where(scheduled_for: Time.zone.today.all_day)
    @service_requests = @care_profile.service_requests.includes(:service_catalog).order(created_at: :desc).limit(3)
    @circle_links = @care_profile.care_profile_links.active.includes(:user).where.not(user: current_user).limit(3)
    @audit_events = @care_profile.audit_events.order(occurred_at: :desc).limit(4)
  end

  def parse_calendar_month
    Date.strptime(params[:month].to_s, "%Y-%m")
  rescue Date::Error
    Time.zone.today.beginning_of_month
  end
end
