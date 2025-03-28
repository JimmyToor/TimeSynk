require "test_helper"

class UserAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_availability = user_availabilities(:user_2)
    @user = users(:two)
    sign_in_as(@user)
  end

  test "should show user_availability" do
    get user_availability_url
    assert_response :success
  end

  test "should get edit" do
    get edit_user_availability_url
    assert_response :success
  end

  test "should update user_availability" do
    new_availability = availabilities(:user_2_empty_availability)
    patch user_availability_url(@user_availability), params: {user_availability: {availability_id: new_availability.id}}
    assert_equal availabilities(:user_2_empty_availability), @user_availability.reload.availability
  end
end
