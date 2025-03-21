require "test_helper"

class GroupMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_membership = group_memberships(:group_2_user_3)
  end

  test "should create group_membership without invite as admin" do
    @user = users(:admin)
    sign_in_as @user
    group = groups(:two_members)

    assert_difference("GroupMembership.count") do
      post group_group_memberships_url group, params: {group_membership: {user_id: @user.id, invite_token: "admin"}, group_id: group.id}
    end

    assert_redirected_to group_url(GroupMembership.last.group)
  end

  test "should not create group_membership without invite" do
    group = groups(:two_members)
    @user = users(:two)
    sign_in_as @user

    assert_no_difference("GroupMembership.count") do
      post group_group_memberships_url group, params: {group_membership: {user_id: users(:three).id}, group_id: group.id}
    end
  end

  test "should show group_membership" do
    @user = users(:two)
    sign_in_as @user

    get group_membership_url(@group_membership)

    assert_response :success
  end

  test "should get edit" do
    @user = users(:two)
    sign_in_as @user

    get edit_group_membership_url(@group_membership)

    assert_response :success
  end

  test "should destroy group_membership" do
    @user = users(:two)
    sign_in_as @user

    assert_difference("GroupMembership.count", -1) do
      delete group_membership_url(@group_membership)
    end

    assert_redirected_to groups_url
  end

  test "should get accept invite page" do
    @user = users(:two)
    sign_in_as(@user)
    invite = invites(:group_1)

    get accept_invite_url(invite_token: invite.invite_token)

    assert_response :success
    assert_recognizes({controller: "invites", action: "show", invite_token: invite.invite_token},
      path: accept_invite_url(invite_token: invite.invite_token))
  end

  test "expired invite should not create membership" do
    @user = users(:two)
    sign_in_as(@user)

    invite = invites(:group_1)

    travel_to 1.week.from_now
    get accept_invite_url(invite_token: invite.invite_token)
    assert_response :unprocessable_entity
  end
end
