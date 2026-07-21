class MembersController < ApplicationController
  def new
    @member = current_user.members.new(preferred_language: "English", relationship_to_user: "family", country: current_user.country)
  end

  def create
    @member = current_user.members.new(member_params)
    if @member.save
      session[:member_id] = @member.id
      redirect_to root_path, notice: "Member profile added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @member = current_user.members.find(current_member.id)
  end

  def update
    @member = current_user.members.find(current_member.id)
    if @member.update(member_params)
      redirect_to root_path, notice: "Member profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def member_params
    params.require(:member).permit(:full_name, :phone_number, :preferred_language, :mobility_needs, :emergency_contact_name, :emergency_contact_phone, :relationship_to_user, :country, :location)
  end
end
