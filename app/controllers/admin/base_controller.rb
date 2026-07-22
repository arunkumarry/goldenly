class Admin::BaseController < ApplicationController
  include AdminSessionAuthentication

  layout "admin"

  skip_before_action :require_authentication
  before_action :require_admin_authentication
  before_action :require_admin_access!

  helper_method :admin_navigation_items

  private

  def admin_navigation_items
    [
      [ "Overview", admin_root_path, "⌂" ],
      [ "Members", admin_members_path, "◉" ],
      [ "Provider applications", admin_providers_path, "✦" ]
    ]
  end

  def member_records
    User.member.left_outer_joins(:care_partner).where(care_partners: { id: nil })
  end
end
