class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to dashboard_path, notice: "Your profile has been updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(:full_name, :email_address, :address, :location, :city, :region, :country, :country_code, :postal_code, :latitude, :longitude, :google_place_id)
  end
end
