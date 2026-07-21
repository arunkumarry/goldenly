class TrustedCircleController < ApplicationController
  def index
    @contacts = current_member.trusted_contacts.order(:name)
    @contact = current_member.trusted_contacts.new(access_level: "Updates")
  end

  def create
    contact = current_member.trusted_contacts.new(contact_params)
    if contact.save
      redirect_to trusted_circle_path, notice: "Trusted contact added."
    else
      @contacts = current_member.trusted_contacts.order(:name)
      @contact = contact
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    current_member.trusted_contacts.find(params[:id]).destroy!
    redirect_to trusted_circle_path, notice: "Trusted contact removed."
  end

  private

  def contact_params
    params.require(:trusted_contact).permit(:name, :relationship, :phone_number, :email, :access_level)
  end
end
