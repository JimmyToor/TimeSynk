require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:cooluserguy)
  end

  test "should sign in with email" do
    visit sign_in_url
    fill_in "username_or_email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on I18n.t("session.new.submit_text")

    assert_current_path root_path
  end

  test "should sign in with username" do
    visit sign_in_url
    fill_in "username_or_email", with: @user.username
    fill_in "Password", with: "Secret1*3*5*"
    find_button(text: I18n.t("session.new.submit_text")).click

    assert_current_path root_path
  end

  test "signing out" do
    sign_in_as @user

    click_on I18n.t("session.destroy.button_text")
    assert_text "That session has been logged out"
  end
end
