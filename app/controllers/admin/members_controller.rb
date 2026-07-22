class Admin::MembersController < Admin::BaseController
  before_action :load_member, only: :show

  def index
    @members = member_records.includes(:owned_care_profiles).order(created_at: :desc)
  end

  def show
    @care_profiles = @member.owned_care_profiles.includes(service_requests: :service_catalog).order(created_at: :desc)
  end

  private

  def load_member
    @member = member_records.find(params[:id])
  end
end
