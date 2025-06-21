class RegistrationsController < ApplicationController
  add_flash_types :success, :info, :error
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  layout "guest"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = {value: session_record.id, httponly: true}

      if @user.email.present?
        send_email_verification
      end
      flash[:success] = t("registration.create.success") if @user.email.present?
      flash[:info] = {message: t("availability.help.no_schedules"),
                      options: {link: {text: "click here", url: edit_availability_path(@user.user_availability.availability)}}}
      redirect_to root_path
    else
      flash.now[:error] = {message: t("registration.create.error"), options: {list_items: @user.errors.full_messages}}
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation, :avatar, :timezone).tap do |user_params|
      user_params[:email] = nil if user_params[:email].blank?
    end
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
