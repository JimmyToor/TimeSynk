require "application_system_test_case"

class Identity::PasswordResetsTest < ApplicationSystemTestCase
  setup do
    @user = users(:radperson)
    @sid = @user.generate_token_for(:password_reset)
  end

  test "sending a password reset email" do
    visit sign_in_url
    click_on "Forgot password?"

    fill_in "Email", with: @user.email
    click_on "Send password reset email"

    assert_text I18n.t("identity.password_reset.email_sent")
  end

  test "updating password" do
    visit edit_identity_password_reset_url(sid: @sid)

    fill_in "New Password", with: "Secret6*4*2*"
    fill_in "Confirm New Password", with: "Secret6*4*2*"
    click_on "Save Changes"

    assert_text I18n.t("identity.password.update.success")
  end
end
