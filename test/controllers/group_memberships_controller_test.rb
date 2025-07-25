require "test_helper"

class GroupMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_membership = group_memberships(:group_2_membership_user_radperson)
    @user = users(:cooluserguy)
    sign_in_as @user
  end

  test "should show group_membership" do
    get group_membership_url(@group_membership)

    assert_response :success
  end

  test "should destroy group_membership" do
    assert_difference("GroupMembership.count", -1) do
      delete group_membership_url(@group_membership)
    end

    assert_redirected_to group_url(@group_membership.group)
  end

  test "should get accept invite page" do
    invite = invites(:group_1_no_roles)

    get accept_invite_url(invite_token: invite.invite_token)

    assert_response :success
  end

  test "should create group_membership from invite" do
    invite = invites(:group_1_no_roles)

    assert_difference("GroupMembership.count", 1) do
      post group_group_memberships_url(params: {group_membership: {user_id: @user.id, invite_token: invite.invite_token}}, group_id: invite.group_id)
    end

    assert_redirected_to group_url(invite.group)
  end

  test "should not create group_membership without invite" do
    group = groups(:one_member)

    assert_no_difference("GroupMembership.count") do
      post group_group_memberships_url(group, params: {group_membership: {user_id: @user.id}, group_id: group.id})
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_membership.invite_not_valid"), flash[:error][:message]
  end

  test "expired invite should result in an expired invite error" do
    invite = invites(:group_1_no_roles)

    travel_to 1.week.from_now

    get accept_invite_url(invite_token: invite.invite_token)
    assert_response :unprocessable_entity
    assert_equal I18n.t("invite.expired"), flash[:error][:options][:list_items][0]
  end

  test "invalid invite should result in an invalid invite error" do
    get accept_invite_url(invite_token: "invalid_token")
    assert_response :unprocessable_entity

    assert_equal I18n.t("invite.invalid"), flash[:error][:options][:list_items][0]
  end
end
