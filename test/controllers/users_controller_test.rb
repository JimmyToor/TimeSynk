require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    sign_in_as(@user)
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user avatar" do
    patch user_url(@user), params: { user: { avatar: fixture_file_upload("avatar/avatar.png", "image/png") } }
    assert_response :success
  end

  test "should not update user with invalid avatar file type" do
    patch user_url(@user), params: { user: { avatar: fixture_file_upload("avatar/avatar_invalid_type.txt", "text/plain") } }
    assert_response :unprocessable_entity
  end

  test "should not update user with invalid avatar file size" do
    patch user_url(@user), params: { user: { avatar: fixture_file_upload("avatar/avatar_invalid_size.png", "image/png") } }
    assert_response :unprocessable_entity
  end

  test "should not update user with png imposter avatar" do
    patch user_url(@user), params: { user: { avatar: fixture_file_upload("avatar/avatar_invalid_imposter.png", "image/png") } }
    assert_response :unprocessable_entity
  end
  
  test "should not update user with corrupt avatar" do
    patch user_url(@user), params: { user: { avatar: fixture_file_upload("avatar/avatar_invalid_corrupt.png", "image/png") } }
    assert_response :unprocessable_entity
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete user_url(@user)
    end

    assert_redirected_to root_url
  end
end
