require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invite = invites(:group_twomembers_role_manage_users)
    @user = users(:cooluserguy)
    sign_in_as(@user)
  end

  test "should get index" do
    get group_invites_url(@invite.group)
    assert_response :success
  end

  test "should get new" do
    get new_group_invite_url(@invite.group)
    assert_response :success
  end

  test "should create invite" do
    group = groups(:two_members)
    role = roles(:group_2_manage_invites)

    assert_difference("Invite.count") do
      post group_invites_url group, params: {invite: {expires_at: 1.day.from_now,
                                                      group_id: group.id,
                                                      assigned_role_ids: ["", role.id],
                                                      user_id: @user.id}}
    end

    assert_redirected_to group_invites_url(group.id)
  end

  test "should create invite as turbo_stream" do
    group = groups(:two_members)
    role = roles(:group_2_manage_invites)

    assert_difference("Invite.count") do
      post group_invites_url(group, format: :turbo_stream), params: {invite: {expires_at: 1.day.from_now,
                                                                              group_id: group.id,
                                                                              assigned_role_ids: ["", role.id],
                                                                              user_id: @user.id}}
    end

    assert_response :success
  end

  test "should not create invite with invalid params" do
    assert_no_difference("Invite.count") do
      post group_invites_url(@invite.group), params: {invite: {expires_at: 1.day.from_now,
                                                               invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                                                               assigned_role_ids: [""],
                                                               user_id: 0}}
    end

    assert_response :unprocessable_entity
    assert_equal flash.now[:error][:message], I18n.t("invite.create.error")
  end

  test "should not create invite with invalid params as turbo_stream" do
    assert_no_difference("Invite.count") do
      post group_invites_url(@invite.group, format: :turbo_stream),
        params: {invite: {expires_at: 1.day.from_now,
                          invite_token: "iWXu1mS7SNgX8xFYGiQGPoCU",
                          assigned_role_ids: [""],
                          user_id: 0}}
    end

    assert_response :unprocessable_entity
    assert_equal flash.now[:error][:message], I18n.t("invite.create.error")
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
    new_expiry_date = @invite.expires_at + 1.week
    assert_changes -> { @invite.expires_at }, to: new_expiry_date do
      patch invite_url(@invite), params: {invite: {expires_at: new_expiry_date,
                                                   group_id: @invite.group_id,
                                                   invite_token: @invite.invite_token,
                                                   assigned_role_ids: @invite.assigned_role_ids,
                                                   user_id: @invite.user_id}}
      @invite.reload
    end

    assert_redirected_to invite_url(@invite)
  end

  test "should update invite as turbo_stream" do
    new_expiry_date = @invite.expires_at + 1.week
    assert_changes -> { @invite.expires_at }, to: new_expiry_date do
      patch invite_url(@invite, format: :turbo_stream), params: {invite: {expires_at: new_expiry_date,
                                                                          group_id: @invite.group_id,
                                                                          invite_token: @invite.invite_token,
                                                                          assigned_role_ids: @invite.assigned_role_ids,
                                                                          user_id: @invite.user_id}}
      @invite.reload
    end

    assert_response :success
  end

  test "should not update invite with invalid params" do
    assert_no_changes -> { @invite.expires_at } do
      patch invite_url(@invite), params: {invite: {expires_at: nil,
                                                   group_id: @invite.group_id,
                                                   invite_token: @invite.invite_token,
                                                   assigned_role_ids: @invite.assigned_role_ids,
                                                   user_id: 0}}
    end

    assert_response :unprocessable_entity
    assert_equal flash.now[:error][:message], I18n.t("invite.update.error")
  end

  test "should not update invite with invalid params as turbo_stream" do
    assert_no_changes -> { @invite.expires_at } do
      patch invite_url(@invite, format: :turbo_stream), params: {invite: {expires_at: nil,
                                                                          group_id: @invite.group_id,
                                                                          invite_token: @invite.invite_token,
                                                                          assigned_role_ids: @invite.assigned_role_ids,
                                                                          user_id: 0}}
    end

    assert_response :unprocessable_entity
    assert_equal flash.now[:error][:message], I18n.t("invite.update.error")
  end

  test "should destroy invite as turbo_stream" do
    assert_difference("Invite.count", -1) do
      delete invite_url(@invite, format: :turbo_stream)
    end

    assert_response :success
  end
end
