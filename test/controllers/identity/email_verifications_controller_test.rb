require "test_helper"

class Identity::EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "should send a verification email" do
    user = sign_in_as(users(:admin))
    user.update! verified: false

    assert_enqueued_email_with UserMailer, :email_verification, params: {user: user} do
      post identity_email_verification_url(user: user, email: user.email)
    end

    assert_redirected_to edit_identity_email_url
  end

  test "should verify email" do
    user = sign_in_as(users(:admin))
    user.update! verified: false
    sid = user.generate_token_for(:email_verification)

    get identity_email_verification_url(sid: sid, email: user.email)
    assert_redirected_to root_url
  end

  test "should not verify email with expired token" do
    user = sign_in_as(users(:admin))
    user.update! verified: false

    sid = user.generate_token_for(:email_verification)

    travel 3.days

    get identity_email_verification_url(sid: sid, email: user.email)

    assert_redirected_to edit_identity_email_url
    assert_equal I18n.t("identity.email.invalid"), flash[:error]
  end

  test "should not verify email if already verified by another user" do
    user = sign_in_as(users(:radperson))
    other_user = users(:admin)
    other_user.update! verified: false

    user.update! email: other_user.email, verified: false

    sid = user.generate_token_for(:email_verification)

    other_user.update! verified: true
    get identity_email_verification_url(sid: sid, email: user.email)

    assert_redirected_to edit_identity_email_url
    assert_equal I18n.t("identity.email.invalid"), flash[:error]
  end
end
