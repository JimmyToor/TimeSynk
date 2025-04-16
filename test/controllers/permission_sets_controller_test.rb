require "test_helper"

class PermissionSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as(users(:two))
  end

  test "should get edit for group" do
    get permission_sets_edit_url, params: {group_id: groups(:three_members).id}
    assert_response :success
  end

  test "should update group permission set" do
    manage_proposals_role = roles(:manage_all_proposals_3)
    create_proposals_role = roles(:create_proposals_3)
    create_invites_role = roles(:create_invites_3)
    user1 = users(:two)
    user2 = users(:three)
    expected_user1_roles = (user1.roles + [manage_proposals_role, create_invites_role]).to_set
    expected_user2_roles = (user2.roles - [create_proposals_role, create_invites_role] + [manage_proposals_role]).to_set

    get permission_sets_update_url, params: {permission_set: {role_changes: {user1.id => {add_roles: [manage_proposals_role.id, create_invites_role.id]},
                                                                             user2.id => {add_roles: [manage_proposals_role.id], remove_roles: [create_proposals_role.id, create_invites_role.id]}}},
                                             update_roles: "",
                                             group_id: groups(:three_members).id}, as: :turbo_stream

    assert_response :success
    user1_roles = user1.reload.roles.to_set
    user2_roles = user2.reload.roles.to_set
    assert_equal expected_user1_roles, user1_roles
    assert_equal expected_user2_roles, user2_roles
  end

  test "should get edit for single group user" do
    user = users(:three)

    get permission_sets_edit_url, params: {group_id: groups(:three_members).id, user_id: user.id}

    assert_response :success
  end

  test "should update single group user permission set" do
    user = users(:three)
    manage_proposals_role = roles(:manage_all_proposals_3)

    get permission_sets_update_url, params: {
      permission_set: {
        role_changes: {
          user.id => {add_roles: [manage_proposals_role.id], remove_roles: []}
        }
      },
      update_roles: "",
      group_id: groups(:three_members).id,
      user_id: user.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes user.reload.roles, manage_proposals_role
  end

  test "should get edit for game proposal" do
    proposal = game_proposals(:group_3_game_1)

    get permission_sets_edit_url, params: {game_proposal_id: proposal.id}

    assert_response :success
  end

  test "should update game proposal permission set" do
    proposal = game_proposals(:group_3_game_1)
    manage_sessions_role = roles(:manage_all_sessions_3)

    get permission_sets_update_url, params: {
      permission_set: {
        role_changes: {
          users(:three).id => {add_roles: [manage_sessions_role.id], remove_roles: []}
        }
      },
      update_roles: "",
      game_proposal_id: proposal.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes users(:three).reload.roles, manage_sessions_role
  end

  test "should get edit for single game proposal user" do
    proposal = game_proposals(:group_3_game_1)
    user = users(:three)

    get permission_sets_edit_url, params: {game_proposal_id: proposal.id, user_id: user.id}

    assert_response :success
  end

  test "should update single game proposal user permission set" do
    proposal = game_proposals(:group_3_game_1)
    user = users(:three)
    role = roles(:game_proposal_1_admin)

    get permission_sets_update_url, params: {
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

  test "should transfer ownership of group" do
    group = groups(:three_members)
    old_owner = User.with_role(:owner, group).first
    new_owner = users(:three)

    get permission_sets_update_url, params: {
      permission_set: {new_owner_id: new_owner.id},
      transfer_ownership: true,
      group_id: group.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes new_owner.reload.roles, roles(:owner_3)
    refute_includes old_owner.reload.roles, roles(:owner_3)
  end

  test "should transfer ownership of game proposal" do
    group = groups(:three_members)
    old_owner = User.with_role(:owner, group).first
    new_owner = users(:three)

    get permission_sets_update_url, params: {
      permission_set: {new_owner_id: new_owner.id},
      transfer_ownership: true,
      group_id: group.id
    }, as: :turbo_stream

    assert_response :success
    assert_includes new_owner.reload.roles, roles(:owner_3)
    refute_includes old_owner.reload.roles, roles(:owner_3)
  end
end
