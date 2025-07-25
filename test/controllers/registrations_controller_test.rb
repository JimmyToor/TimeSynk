require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sign_up_url
    assert_response :success
  end

  test "should sign up" do
    assert_difference("User.count") do
      post sign_up_url, params: {user: {email: "newuser@hotmail.com", username: "new user", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_redirected_to root_url
  end

  test "should sign up with blank email" do
    assert_difference("User.count") do
      post sign_up_url, params: {user: {email: "", username: "new user", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_redirected_to root_url
  end

  test "should sign up with null email" do
    assert_difference("User.count") do
      post sign_up_url, params: {user: {username: "new user", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_redirected_to root_url
  end

  test "should fail to sign up with existing verified email" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "Cooluserguy@hotmail.com", username: "new user", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_match(/Email is already taken/, response.body)
  end

  test "should fail to sign up with a blank username" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newemail@email.com", username: "", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_match(/Username cannot be blank./, response.body)
  end

  test "should fail to sign up with no username" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newemail@email.com", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_match(/Username cannot be blank./, response.body)
  end

  test "should fail to sign up with existing username" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newemail@email.com", username: "Cooluserguy", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_match(/Username has already been taken/, response.body)
  end

  test "should fail to sign up with a short username" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newemail@email.com", username: "ab", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_match(/Username is too short/, response.body)
  end

  test "should fail to sign up with invalid email" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newuser", username: "new user", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_select "li", /Email is invalid/
  end

  test "should fail to sign up with invalid password" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newuser@hotmail.com", username: "new user", password: "S", password_confirmation: "S", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_select "li", /Password/
  end

  test "should fail to sign up with invalid password confirmation" do
    assert_no_difference("User.count") do
      post sign_up_url, params: {user: {email: "newuser@hotmail.com", username: "new user", password: "S", password_confirmation: "Sa", timezone: "America/Los_Angeles", avatar: ""}}
    end

    assert_response :unprocessable_entity
    assert_select "li", /Password confirmation doesn't match password./
  end
end
