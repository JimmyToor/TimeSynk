require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as(users(:two))
  end

  test "should get edit" do
    get edit_password_url
    assert_response :success
  end

  test "should update password" do
    patch password_url, params: {user: {password_challenge: "Secret1*3*5*", password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*"}}
    assert_redirected_to settings_url
  end

  test "should not update password with wrong password challenge" do
    patch password_url, params: {user: {password_challenge: "SecretWrong1*3", password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*"}}

    assert_response :unprocessable_entity
    assert_select "li", /Current password is incorrect./
  end
end
