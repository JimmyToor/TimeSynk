require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:two_members)
    @user = users(:two)
    sign_in_as @user
  end

  test "should get index" do
    get groups_url
    assert_response :success
    assert_match /First Group/, response.body
    assert_match /Second Group/, response.body
  end

  test "should get new" do
    get new_group_url
    assert_response :success
    assert_match /Create Group/, response.body
  end

  test "should create group" do
    assert_difference("Group.count") do
      post groups_url, params: { group: { name: "New Group Name" } }
    end

    assert_redirected_to group_url(Group.last)
  end

  test "should show group" do
    get group_url(@group)
    assert_response :success
    assert_match /Second Group/, response.body
  end

  test "should get edit" do
    get edit_group_url(@group)
    assert_response :success
    assert_match /Update Group/, response.body
  end

  test "should update group" do
    patch group_url(@group), params: { group: { name: "different" } }
    assert_redirected_to group_url(@group)
    assert_equal "different", @group.reload.name
  end

  test "should destroy group" do
    assert_difference("Group.count", -1) do
      delete group_url(@group)
    end

    assert_redirected_to groups_url
  end
end
