class EmergencyAlertsController < ApplicationController
  before_action -> { require_care_profile_permission!(:emergency_alerts, :manage, emergency: true) }

  def new
    @care_profile = current_care_profile
    @emergency_number = CountryEmergencyNumber.for(@care_profile.country)
  end

  def create
    action = CareActionPlanner.new(care_profile: current_care_profile, message: "SOS emergency help").plan
    result = CareActionExecutor.new(care_profile: current_care_profile, action:, share_location: params[:share_location], actor: current_user).confirm
    redirect_to nearby_hospitals_path, notice: "#{result[:message]} Use #{action.fetch('emergency_number')} for immediate emergency help."
  end
end
