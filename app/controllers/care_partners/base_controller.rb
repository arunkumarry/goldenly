class CarePartners::BaseController < ApplicationController
  include CarePartnerSessionAuthentication

  layout "care_partner"

  skip_before_action :require_authentication
  before_action :require_care_partner_authentication
  before_action :ensure_care_partner_account!

  helper_method :current_care_partner_account

  private

  def current_care_partner_account
    @current_care_partner_account ||= current_care_partner_user.care_partner_account
  end

  def ensure_care_partner_account!
    @current_care_partner_account ||= current_care_partner_user.care_partner_account || current_care_partner_user.create_care_partner_account!
    @current_care_partner_account.profile || @current_care_partner_account.create_profile!
  end

end
