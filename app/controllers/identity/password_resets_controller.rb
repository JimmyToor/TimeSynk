class Identity::PasswordResetsController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :set_user, only: %i[edit update]
  layout "guest"

  def new
  end

  def edit
  end

  def create
    @user = User.find_by(email: params[:email], verified: true)
    if @user
      send_password_reset_email
      redirect_to sign_in_path, notice: "Check your email for reset instructions"
    else
      redirect_to new_identity_password_reset_path, alert: "You can't reset your password until you verify your email"
    end
  end

  def update
    if @user.update(user_params)
      redirect_to sign_in_path, notice: "Your password was reset successfully. Please sign in"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by_token_for!(:password_reset, params[:sid])
  rescue
    redirect_to new_identity_password_reset_path, alert: "That password reset link is invalid"
  end

  def user_params
    params.permit(:password, :password_confirmation)
  end

  def send_password_reset_email
    UserMailer.with(user: @user).password_reset.deliver_later
  end
end
