class Identity::EmailVerificationsController < ApplicationController
  before_action :set_user, only: :show
  before_action :check_if_email_verified_by_other_user, only: %i[show create]
  skip_before_action :authenticate, only: :show
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show
    @user.update! verified: true
    redirect_to root_path, notice: "Thank you for verifying your email address"
  end

  def create
    send_email_verification
    redirect_to edit_identity_email_path, notice: "Verification email sent to #{params[:email]}"
  end

  private

  def set_user
    @user = User.find_by_token_for!(:email_verification, params[:sid])
  rescue
    redirect_to edit_identity_email_path, alert: I18n.t("identity.email.invalid")
  end

  def send_email_verification
    UserMailer.with(user: Current.user).email_verification.deliver_later
  end

  def check_if_email_verified_by_other_user
    email = if params[:email].present?
      params[:email]
    else
      @user&.email
    end

    redirect_to edit_identity_email_path, alert: "You must enter a valid email address." unless email.present? and return

    if User.where(email: email, verified: true).exists?
      redirect_to edit_identity_email_path, alert: "This email is already verified by another user."
    end
  end
end
