class MemberSelectionsController < ApplicationController
  def update
    member = current_user.members.find(params.require(:member_id))
    session[:member_id] = member.id
    redirect_to params.fetch(:return_to, root_path), notice: "Now viewing #{member.full_name}."
  end
end
