require "test_helper"

class Identity::EmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as(users(:admin))
  end

  test "should get edit" do
    get edit_identity_email_url
    assert_response :success
  end

  test "should update email" do
    patch identity_email_url, params: {user: {email: "new_email@hey.com", password_challenge: "Secret1*3*5*"}}
    assert_equal "new_email@hey.com", @user.reload.email
    assert_redirected_to edit_identity_email_path
  end

  test "should not update email with wrong password challenge" do
    patch identity_email_url, params: {user: {email: "new_email@hey.com", password_challenge: "SecretWrong1*3"}}

    assert_response :unprocessable_entity
    assert_select "li", /Current password is incorrect/
  end
end
