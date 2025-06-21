class Identity::EmailVerificationsController < ApplicationController
  add_flash_types :success, :error, :notice
  before_action :set_user, only: :show
  before_action :set_email, only: %i[show create]
  before_action :check_if_email_verified, only: %i[show create]
  skip_before_action :authenticate, only: :show
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show
    @user.update! verified: true
    redirect_to root_path, notice: "Your email address is now verified."
  end

  def create
    send_email_verification
    redirect_to edit_identity_email_path,
      notice: {message: "Verification email sent to #{params[:email]}. It may be in your spam folder.",
               options: {highlight: params[:email]}}
  end

  private

  def set_user
    @user = User.find_by_token_for!(:email_verification, params[:sid])
  rescue
    redirect_to edit_identity_email_path, error: I18n.t("identity.email.invalid") and return
  end

  def send_email_verification
    UserMailer.with(user: Current.user).email_verification.deliver_later
  end

  def check_if_email_verified
    redirect_to edit_identity_email_path, error: "You must enter a valid email address." and return unless @email.present?
    redirect_to edit_identity_email_path, notice: "You have already verified this email." and return if email_verified_by_same_user?
    redirect_to edit_identity_email_path, notice: "This email is already verified by another user." if email_verified_by_other_user?
  end

  def email_verified_by_same_user?
    @user&.email == @email && @user&.verified
  end

  def email_verified_by_other_user?
    User.where(email: @email, verified: true).exists?
  end

  def set_email
    @email = if params[:email].present?
      params[:email]
    else
      @user&.email
    end
  end
end
