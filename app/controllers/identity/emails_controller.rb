class Identity::EmailsController < ApplicationController
  before_action :check_if_email_verified_by_other_user, only: %i[update]
  before_action :set_user
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to_root
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.permit(:email, :password_challenge).with_defaults(password_challenge: "")
  end

  def redirect_to_root
    if @user.email_previously_changed?
      msg = I18n.t("identity.email.update.success")
      msg += I18n.t("identity.email.verification_sent", email: @user.email) unless @user.email.blank?
      resend_email_verification
      redirect_to root_path, success: {message: msg, options: {highlight: @user.email}}
    else
      redirect_to root_path
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
