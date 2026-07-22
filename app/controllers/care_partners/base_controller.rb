class CarePartners::BaseController < ApplicationController
  include CarePartnerSessionAuthentication

  layout "care_partner"

  skip_before_action :require_authentication
  before_action :require_care_partner_authentication
  before_action :ensure_care_partner!

  private

  def ensure_care_partner!
    @current_care_partner ||= current_care_partner_user.care_partner || current_care_partner_user.create_care_partner!
    @current_care_partner.profile || @current_care_partner.create_profile!
  end

end
