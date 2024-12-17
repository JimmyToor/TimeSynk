require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
  end

  test "should get new" do
    get sign_in_url
    assert_response :success
  end

  test "should sign in" do
    post sign_in_url, params: { username_or_email: @user.email, password: "Secret1*3*5*" }
    assert_redirected_to root_url

    get root_url
    assert_response :success
  end

  test "should sign in with username" do
    post sign_in_url, params: { username_or_email: @user.username, password: "Secret1*3*5*" }
    assert_redirected_to root_url

    get root_url
    assert_response :success
  end

  test "should sign in with different case email" do
    post sign_in_url, params: { username_or_email: @user.email.upcase, password: "Secret1*3*5*" }
    assert_redirected_to root_url

    get root_url
    assert_response :success
  end

  test "should sign in with different case username" do
    post sign_in_url, params: { username_or_email: @user.username.upcase, password: "Secret1*3*5*" }
    assert_redirected_to root_url

    get root_url
    assert_response :success
  end

  test "should not sign in with wrong credentials" do
    post sign_in_url, params: { username_or_email: @user.email, password: "SecretWrong1*3" }
    assert_redirected_to sign_in_url(email_hint: @user.email)
    assert_equal "That email or password is incorrect", flash[:alert]

    get root_url
    assert_redirected_to sign_in_url
  end

  test "should sign out" do
    sign_in_as @user

    delete session_url(@user.sessions.last)
    assert_redirected_to sessions_url

    follow_redirect!
    assert_redirected_to sign_in_url
  end
end
