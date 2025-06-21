class Identity::EmailsController < ApplicationController
  add_flash_types :success, :error
  before_action :check_if_email_verified_by_other_user, only: %i[update]
  before_action :set_user
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def edit
  end

  def update
    original_email = @user.email
    original_verified_status = @user.verified

    if @user.update(user_params)
      redirect_to_edit
    else
      @user.email = original_email
      @user.verified = original_verified_status
      flash.now[:error] = {message: I18n.t("identity.email.update.error"), options: {list_items: @user.errors.full_messages}}
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.require(:user).permit(:email, :password_challenge).with_defaults(password_challenge: "")
  end

  def redirect_to_edit
    if @user.email_previously_changed?
      if @user.email.blank?
        redirect_to edit_identity_email_path, success: {message: I18n.t("identity.email.destroy.success")}
      else
        resend_email_verification
        redirect_to edit_identity_email_path, success: {
          message: "#{I18n.t("identity.email.update.success")} #{I18n.t("identity.email.verification_sent", email: @user.email)}",
          options: {highlight: @user.email}
        }
      end
    else
      redirect_to edit_identity_email_path
    end
  end

  def resend_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end

  def check_if_email_verified_by_other_user
    if User.where(email: params[:email] || @user&.email, verified: true).exists?
      redirect_to edit_identity_email_path, alert: I18n.t("identity.email.already_verified")
    end
  end
end
