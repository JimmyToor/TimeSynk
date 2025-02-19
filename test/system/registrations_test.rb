require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "signing up" do
    visit sign_up_url

    fill_in "Email", with: "NewUser@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_current_path root_path
  end

  test "signing up with blank email" do
    visit sign_up_url

    fill_in "Email", with: ""
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_current_path root_path
  end

  test "signing up with null email" do
    visit sign_up_url

    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_current_path root_path
  end

  test "failing to sign up with a short username" do
    visit sign_up_url

    fill_in "Email", with: "Cooluserguy@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_text "Username has already been taken"
  end

  test "failing to sign up with existing email" do
    visit sign_up_url

    fill_in "Email", with: "Cooluserguy@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_text "Email has already been taken"
  end

  test "failing to sign up with existing username" do
    visit sign_up_url

    fill_in "Email", with: "newemail@email.com"
    fill_in "Username", with: "New User"
    fill_in "Username", with: "Cooluserguy"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_text "Username has already been taken"
  end

  test "failing to sign up with invalid email" do
    visit sign_up_url

    fill_in "Email", with: "newuser"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "Secret1*3*5*"
    fill_in "Confirm Password", with: "Secret1*3*5*"
    check "terms"
    click_on "Create an account"
    assert_text "Email is invalid"
  end

  test "failing to sign up with invalid password" do
    visit sign_up_url

    fill_in "Email", with: "newuser@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "S"
    fill_in "Confirm Password", with: "S"
    check "terms"
    click_on "Create an account"
    assert_text "Password is too short"
  end

  test "failing to sign up with invalid password confirmation" do
    visit sign_up_url

    fill_in "Email", with: "newuser@hotmail.com"
    fill_in "Username", with: "New User"
    fill_in "Password", with: "S"
    fill_in "Confirm Password", with: "Sa"
    check "terms"
    click_on "Create an account"
    assert_text "Password confirmation doesn&#39;t match Password"
  end
end