require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invite = invites(:one)
  end

  test "should get index" do
    get invites
    assert_response :success
  end

  test "should get new" do
    get new_group_invite_url
    assert_response :success
  end

  test "should create invite" do
    assert_difference("Invite.count") do
      post group_invites_url, params: { invite: { expires_at: @invite.expires_at, group_id: @invite.group_id, invite_token: @invite.invite_token, roles: @invite.role_ids, user_id: @invite.user_id } }
    end

    assert_redirected_to invite_url(Invite.last)
  end

  test "should show invite" do
    get invite_url(@invite)
    assert_response :success
  end

  test "should get edit" do
    get edit_invite_url(@invite)
    assert_response :success
  end

  test "should update invite" do
    patch invite_url(@invite), params: { invite: { expires_at: @invite.expires_at, group_id: @invite.group_id, invite_token: @invite.invite_token, role_ids: @invite.role_ids, user_id: @invite.user_id } }
    assert_redirected_to invite_url(@invite)
  end

  test "should destroy invite" do
    assert_difference("Invite.count", -1) do
      delete invite_url(@invite)
    end

    assert_redirected_to group_invites_url
  end
end
