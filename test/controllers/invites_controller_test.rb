require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invite = invites(:group_1_no_roles)
  end

  test "should get index" do
    @user = users(:admin)
    sign_in_as(@user)

    get group_invites_url(@invite.group)
    assert_response :success
  end

  test "should get new" do
    @user = users(:admin)
    sign_in_as(@user)

    get new_group_invite_url(@invite.group)
    assert_response :success
  end

  test "should create invite" do
    @user = users(:admin)
    sign_in_as(@user)
    group = groups(:one_member)
    role = roles(:manage_invites_1)

    assert_difference("Invite.count") do
      post group_invites_url group, params: {invite: {expires_at: 1.day.from_now,
                                                      group_id: group.id,
                                                      invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                      assigned_role_ids: ["", role.id],
                                                      user_id: @user.id}}
    end

    assert_redirected_to group_invites_url(group.id)
  end

  test "should not create invite with invalid group" do
    @user = users(:admin)
    sign_in_as(@user)

    assert_no_difference("Invite.count") do
      post group_invites_url(group_id: 0), params: {invite: {expires_at: 1.day.from_now,
                                                             group_id: 0,
                                                             invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                             assigned_role_ids: ["", 1],
                                                             user_id: @user.id}}
    end
  end

  test "should not create invite with invalid user" do
    @user = users(:admin)
    sign_in_as(@user)

    assert_no_difference("Invite.count") do
      post group_invites_url(@invite.group), params: {invite: {expires_at: 1.day.from_now,
                                                               group_id: @invite.group.id,
                                                               invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                               assigned_role_ids: ["", 1],
                                                               user_id: 0}}
    end
  end

  test "should not create invite with invalid assigned roles" do
    @user = users(:admin)
    sign_in_as(@user)

    assert_no_difference("Invite.count") do
      post group_invites_url(@invite.group), params: {invite: {expires_at: 1.day.from_now,
                                                               group_id: @invite.group.id,
                                                               invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                               assigned_role_ids: [0],
                                                               user_id: @user.id}}
    end
    assert_response :forbidden
  end

  test "admin should get new with valid roles" do
    @user = users(:admin)
    sign_in_as(@user)

    get new_group_invite_url(@invite.group)
    assert_response :success
    Invite.available_roles(@user, @invite.group).each do |role|
      assert_select "input", value: role.id
    end
  end

  test "non-admin should get new with no roles" do
    @user = users(:radperson)
    sign_in_as(@user)

    get new_group_invite_url(groups(:three_members))
    assert_response :success
    assert_select "option", count: 0
  end

  test "should not create invite for another user" do
    @user = users(:radperson)
    sign_in_as(@user)

    assert_no_difference("Invite.count") do
      post group_invites_url(@invite.group), params: {invite: {expires_at: 1.day.from_now,
                                                               group_id: groups(:three_members).id,
                                                               invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                               assigned_role_ids: ["", 1],
                                                               user_id: users(:cooluserguy).id}}
    end

    assert_response :forbidden
  end

  test "should not create invite for another group" do
    @user = users(:radperson)
    sign_in_as(@user)
    group = groups(:one_member)

    assert_no_difference("Invite.count") do
      post group_invites_url(group), params: {invite: {expires_at: 1.day.from_now,
                                                       group_id: group.id,
                                                       invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                       assigned_role_ids: ["", 1],
                                                       user_id: @user.id}}
    end

    assert_response :forbidden
  end

  test "should show invite" do
    @user = users(:admin)
    sign_in_as(@user)
    get invite_url(@invite)
    assert_response :success
  end

  test "should get edit" do
    @user = users(:admin)
    sign_in_as(@user)
    get edit_invite_url(@invite)
    assert_response :success
  end

  test "should update invite" do
    @user = users(:admin)
    sign_in_as(@user)
    patch invite_url(@invite), params: {invite: {expires_at: @invite.expires_at,
                                                 group_id: @invite.group_id,
                                                 invite_token: @invite.invite_token,
                                                 assigned_role_ids: @invite.assigned_role_ids,
                                                 user_id: @invite.user_id}}
    assert_redirected_to invite_url(@invite)
  end

  test "should destroy invite" do
    @user = users(:admin)
    sign_in_as(@user)
    assert_difference("Invite.count", -1) do
      delete invite_url(@invite)
    end

    assert_redirected_to group_invites_url(@invite.group)
  end
end
