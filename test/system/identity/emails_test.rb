require "application_system_test_case"

class Identity::EmailsTest < ApplicationSystemTestCase
  setup do
    @user = sign_in_as(users(:radperson))
  end

  test "updating the email" do
    visit settings_url
    click_on "Change email address"

    fill_in "New Email", with: "new_email@hey.com"
    fill_in "Current Password", with: "Secret1*3*5*"
    click_on "Save Changes"

    assert_text "Your email has been changed"
  end

  test "sending a verification email" do
    new_email = "testemail@testdomain.com"
    @user.update!(email: new_email, verified: false)
    visit settings_url
    click_on "Change email address"
    click_on "Re-send verification email"

    assert_text I18n.t("identity.email.verification_sent", email: new_email)
  end
end
