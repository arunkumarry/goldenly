class CareProfileSelectionsController < ApplicationController
  def update
    care_profile = current_user.active_care_profile_links.find_by!(care_profile_id: params.require(:care_profile_id)).care_profile
    session[:care_profile_id] = care_profile.id
    redirect_to params.fetch(:return_to, root_path), notice: "Now viewing #{care_profile.full_name}'s care."
  end
end
