require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:two_members)
    @user = users(:cooluserguy)
    sign_in_as @user
  end

  test "should get index" do
    get groups_url
    assert_response :success
  end

  test "should get new" do
    get new_group_url
    assert_response :success
  end

  test "should create group as turbo_stream" do
    assert_difference("Group.count") do
      post groups_url(format: :turbo_stream), params: {group: {name: "New Group Name"}}
    end

    assert_redirected_to group_url(Group.last)
  end

  test "should not create group with invalid params as turbo_stream" do
    assert_no_difference("Group.count") do
      post groups_url(format: :turbo_stream), params: {group: {name: ""}}
    end

    assert_response :unprocessable_entity
  end

  test "should show group" do
    get group_url(@group)
    assert_response :success
  end

  test "should get edit" do
    get edit_group_url(@group)
    assert_response :success
  end

  test "should update group as turbo_stream" do
    new_name = "DifferentName"

    assert_changes -> { @group.name }, to: new_name do
      patch group_url(@group, format: :turbo_stream), params: {group: {name: new_name}}
      @group.reload
    end

    assert_response :success
  end

  test "should not update group with invalid params as turbo_stream" do
    assert_no_changes -> { @group.name } do
      patch group_url(@group, format: :turbo_stream), params: {group: {name: ""}}
      @group.reload
    end

    assert_response :unprocessable_entity
    assert_equal flash.now[:error][:message], I18n.t("group.update.error")
  end

  test "should destroy group as turbo_stream" do
    assert_difference("Group.count", -1) do
      delete group_url(@group, format: :turbo_stream)
    end

    assert_redirected_to groups_url
  end
end
