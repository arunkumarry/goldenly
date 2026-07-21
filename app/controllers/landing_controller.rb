class LandingController < ApplicationController
  skip_before_action :require_authentication

  def index; end

  def provider; end
end
