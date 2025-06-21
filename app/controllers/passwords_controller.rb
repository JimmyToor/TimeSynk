class PasswordsController < ApplicationController
  add_flash_types :success, :error
  before_action :set_user
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to settings_path, success: {message: I18n.t("identity.password.update.success")}
    else
      flash.now[:error] = {message: I18n.t("identity.password.update.error"), options: {list_items: @user.errors.full_messages}}
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :password_challenge).with_defaults(password_challenge: "")
  end
end
