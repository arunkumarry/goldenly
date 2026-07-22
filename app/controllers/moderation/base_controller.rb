class Moderation::BaseController < ApplicationController
  include CarePartnerSessionAuthentication

  layout "care_partner"

  skip_before_action :require_authentication
  before_action :require_care_partner_authentication
  before_action :require_care_partner_reviewer!

  private

  def require_care_partner_reviewer!
    return if current_user.can_review_care_partners?

    redirect_to dashboard_path, alert: "Moderator access is required."
  end
end
