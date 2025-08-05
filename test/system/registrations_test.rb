require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "signing up" do
    visit sign_up_url

    fill_in "user_email", with: "NewUser@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    click_on "Create an account"

    assert_current_path root_path
  end

  test "signing up with blank email" do
    visit sign_up_url

    fill_in "user_email", with: ""
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    click_on "Create an account"

    assert_current_path root_path
  end

  test "signing up with null email" do
    visit sign_up_url

    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    click_on "Create an account"

    assert_current_path root_path
  end

  test "failing to sign up with existing email" do
    visit sign_up_url

    fill_in "Email", with: "Cooluserguy@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    click_on "Create an account"

    assert_text I18n.t("registration.create.error")
  end

  test "failing to sign up with existing username" do
    visit sign_up_url

    fill_in "Username", with: "Cooluserguy"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    click_on "Create an account"

    assert_text I18n.t("registration.create.error")
  end

  test "failing to sign up with invalid password confirmation" do
    visit sign_up_url

    fill_in "Email", with: "newuser@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "abcdefgh"
    fill_in "Confirm Password", with: "hgfedcba"
    click_on "Create an account"

    assert_text I18n.t("activerecord.attributes.user.password_confirmation")
  end
end
