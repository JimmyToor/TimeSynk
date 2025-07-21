require "test_helper"

class PermissionSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as(users(:cooluserguy))
  end

  test "should get show for group" do
    group = groups(:three_members)
    user = users(:radperson)
    get group_permission_set_url(group), params: {user_id: user.id}
    assert_response :success
  end

  test "should get show for game proposal" do
    game_proposal = game_proposals(:group_2_game_gta)
    user = users(:radperson)
    get game_proposal_permission_set_url(game_proposal), params: {user_id: user.id}
    assert_response :success
  end

  test "should get edit for group" do
    group = groups(:three_members)
    get edit_group_permission_set_url(group.id)
    assert_response :success
  end

  test "should update group permission set" do
    manage_proposals_role = roles(:group_3_manage_all_proposals)
    create_proposals_role = roles(:group_3_create_game_proposals)
    create_invites_role = roles(:group_3_create_invites)
    user1 = users(:cooluserguy)
    user2 = users(:radperson)
    expected_user1_roles = (user1.roles + [manage_proposals_role, create_invites_role]).to_set
    expected_user2_roles = (user2.roles - [create_proposals_role, create_invites_role] + [manage_proposals_role]).to_set
    group = groups(:three_members)

    patch group_permission_set_url(group.id), params: {permission_set: {role_changes: {user1.id => {add_roles: [manage_proposals_role.id, create_invites_role.id]},
                                                                                       user2.id => {add_roles: [manage_proposals_role.id], remove_roles: [create_proposals_role.id, create_invites_role.id]}}},
                                                       update_roles: "",
                                                       group_id: group.id}, as: :turbo_stream

    assert_response :success
    user1_roles = user1.reload.roles.to_set
    user2_roles = user2.reload.roles.to_set
    assert_equal expected_user1_roles, user1_roles
    assert_equal expected_user2_roles, user2_roles
  end

  test "should get edit for single group user" do
    user = users(:radperson)
    group = groups(:three_members)
    get edit_group_permission_set_url(group), params: {user_id: user.id}

    assert_response :success
  end

  test "should update single group user permission set" do
    user = users(:radperson)
    manage_proposals_role = roles(:group_3_manage_all_proposals)
    group = groups(:three_members)
    patch group_permission_set_url(group.id), params: {
      permission_set: {
        role_changes: {
          user.id => {add_roles: [manage_proposals_role.id], remove_roles: []}
        }
      },
      update_roles: "",
      group_id: group.id,
      user_id: user.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes user.reload.roles, manage_proposals_role
  end

  test "should get edit for game proposal" do
    proposal = game_proposals(:group_3_game_thief)

    get edit_game_proposal_permission_set_url(proposal.id), params: {game_proposal_id: proposal.id}

    assert_response :success
  end

  test "should update game proposal permission set" do
    proposal = game_proposals(:group_3_game_thief)
    manage_sessions_role = roles(:group_3_game_thief_manage_all_game_sessions)

    patch game_proposal_permission_set_url(proposal.id), params: {
      permission_set: {
        role_changes: {
          users(:radperson).id => {add_roles: [manage_sessions_role.id], remove_roles: []}
        }
      },
      update_roles: "",
      game_proposal_id: proposal.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes users(:radperson).reload.roles, manage_sessions_role
  end

  test "should get edit for single game proposal user" do
    proposal = game_proposals(:group_3_game_thief)
    user = users(:radperson)

    get edit_game_proposal_permission_set_url(proposal.id), params: {game_proposal_id: proposal.id, user_id: user.id}

    assert_response :success
  end

  test "should update single game proposal user permission set" do
    proposal = game_proposals(:group_3_game_thief)
    user = users(:radperson)
    role = roles(:group_1_game_thief_admin)

    patch game_proposal_permission_set_url(proposal.id), params: {
      permission_set: {
        role_changes: {
          user.id => {add_roles: [role.id], remove_roles: []}
        }
      },
      update_roles: "",
      game_proposal_id: proposal.id,
      user_id: user.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes user.reload.roles, role
  end
end
