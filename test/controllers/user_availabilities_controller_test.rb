require "test_helper"

class UserAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_availability = user_availabilities(:one)
  end

  test "should get index" do
    get user_availabilities_url
    assert_response :success
  end

  test "should get new" do
    get new_user_availability_url
    assert_response :success
  end

  test "should create user_availability" do
    assert_difference("UserAvailability.count") do
      post user_availabilities_url, params: { user_availability: { schedule_id: @user_availability.schedule_id, user_id: @user_availability.user_id } }
    end

    assert_redirected_to user_availability_url(UserAvailability.last)
  end

  test "should show user_availability" do
    get user_availability_url(@user_availability)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_availability_url(@user_availability)
    assert_response :success
  end

  test "should update user_availability" do
    patch user_availability_url(@user_availability), params: { user_availability: { schedule_id: @user_availability.schedule_id, user_id: @user_availability.user_id } }
    assert_redirected_to user_availability_url(@user_availability)
  end

  test "should destroy user_availability" do
    assert_difference("UserAvailability.count", -1) do
      delete user_availability_url(@user_availability)
    end

    assert_redirected_to user_availabilities_url
  end
end
