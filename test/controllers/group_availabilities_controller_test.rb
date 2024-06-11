require "test_helper"

class GroupAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_availability = group_availabilities(:one)
  end

  test "should get index" do
    get group_availabilities_url
    assert_response :success
  end

  test "should get new" do
    get new_group_availability_url
    assert_response :success
  end

  test "should create group_availability" do
    assert_difference("GroupAvailability.count") do
      post group_availabilities_url, params: { group_availability: { group_id: @group_availability.group_id, schedule_id: @group_availability.schedule_id, user_id: @group_availability.user_id } }
    end

    assert_redirected_to group_availability_url(GroupAvailability.last)
  end

  test "should show group_availability" do
    get group_availability_url(@group_availability)
    assert_response :success
  end

  test "should get edit" do
    get edit_group_availability_url(@group_availability)
    assert_response :success
  end

  test "should update group_availability" do
    patch group_availability_url(@group_availability), params: { group_availability: { group_id: @group_availability.group_id, schedule_id: @group_availability.schedule_id, user_id: @group_availability.user_id } }
    assert_redirected_to group_availability_url(@group_availability)
  end

  test "should destroy group_availability" do
    assert_difference("GroupAvailability.count", -1) do
      delete group_availability_url(@group_availability)
    end

    assert_redirected_to group_availabilities_url
  end
end
