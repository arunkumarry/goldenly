class UsersController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  def new
    @user = User.new
    @member = Member.new(relationship_to_user: "self", preferred_language: "English")
  end

  def create
    identifier = AuthenticationIdentifier.normalize(params[:identifier])
    if AuthenticationIdentifier.find_user(identifier)
      flash.now[:alert] = "An account already exists for that email or phone number."
      return render :new, status: :unprocessable_content
    end

    @user = User.new(user_params)
    AuthenticationIdentifier.assign(@user, identifier)
    @member = @user.members.build(member_params)
    if @user.valid? && @member.valid?
      session[:pending_signup] = { "identifier" => identifier, "user" => user_params.to_h, "member" => member_params.to_h }
      TwilioVerify.send_code(identifier)
      redirect_to verify_users_path, notice: "We sent a verification code to #{identifier}."
    else
      render :new, status: :unprocessable_content
    end
  rescue AuthenticationIdentifier::InvalidIdentifier, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    @user ||= User.new(user_params)
    @member ||= @user.members.build(member_params)
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end

  def verify
    redirect_to new_user_path unless pending_signup
  end

  def confirm
    signup = pending_signup
    return redirect_to new_user_path, alert: "Start signup again." unless signup

    unless TwilioVerify.approved?(signup.fetch("identifier"), params[:code])
      flash.now[:alert] = "That verification code is invalid or has expired."
      return render :verify, status: :unprocessable_content
    end

    User.transaction do
      @user = User.new(signup.fetch("user"))
      AuthenticationIdentifier.assign(@user, signup.fetch("identifier"))
      @user.verified_at = Time.current
      @user.save!
      @member = @user.members.create!(signup.fetch("member"))
    end
    session.delete(:pending_signup)
    session[:user_id] = @user.id
    redirect_to root_path, notice: "Welcome to Goldenly, #{@user.full_name}!"
  rescue ActiveRecord::RecordInvalid, TwilioVerify::ConfigurationError, Twilio::REST::RestError => error
    flash.now[:alert] = error.message
    render :verify, status: :unprocessable_content
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :country, :location)
  end

  def member_params
    params.require(:member).permit(:full_name, :phone_number, :preferred_language, :relationship_to_user, :country, :location)
  end

  def pending_signup
    session[:pending_signup]
  end
end
