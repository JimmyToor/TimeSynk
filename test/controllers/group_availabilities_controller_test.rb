require "test_helper"

class GroupAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_availability = group_availabilities(:user_2_group_2_availability)
    @group_availability = group_availabilities(:user_cooluserguy_group_2_availability)
  end

  test "should get index" do
    user = users(:cooluserguy)
    sign_in_as(user)

    get group_availabilities_url
    assert_response :success
  end

  test "should get new" do
    user = users(:radperson)
    sign_in_as(user)

    get new_group_group_availability_url(groups(:three_members))
    assert_response :success
  end

  test "new should get edit when there is an existing group_availability" do
    user = users(:cooluserguy)
    sign_in_as(user)

    get new_group_group_availability_url(groups(:two_members))
    assert_redirected_to edit_group_availability_url(group_availabilities(:user_cooluserguy_group_2_availability))
  end

  test "should create group_availability" do
    user = users(:radperson)
    sign_in_as(user)
    group = groups(:three_members)

    assert_difference("GroupAvailability.count") do
      post group_group_availabilities_url(group),
        params: {group_availability: {availability_id: availabilities(:user_radperson_default_availability).id,
                                      group_id: group.id,
                                      user_id: @user.id}}
    end

    assert_redirected_to group_url(group)
  end

  test "should show group_availability" do
    user = users(:cooluserguy)
    sign_in_as(user)

    get group_availability_url(@group_availability)
    assert_response :success
  end

  test "should get edit" do
    user = users(:cooluserguy)
    sign_in_as(user)

    get edit_group_availability_url(@group_availability)
    assert_response :success
  end

  test "should update group_availability" do
    availability = availabilities(:user_cooluserguy_empty_availability)

    patch group_availability_url(@group_availability), params: {group_availability: {availability_id: availability.id}}

    assert_redirected_to group_url(@group_availability.group)
    assert_equal availability, @group_availability.reload.availability
  end

  test "should destroy group_availability" do
    user = users(:cooluserguy)
    sign_in_as(user)

    assert_difference("GroupAvailability.count", -1) do
      delete group_availability_url(@group_availability)
    end

    assert_redirected_to group_url(@group_availability.group)
  end
end
