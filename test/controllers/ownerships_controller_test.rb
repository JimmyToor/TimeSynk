require "test_helper"

class OwnershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:cooluserguy)
    sign_in_as @user
  end

  test "should update ownership of group with turbo_stream" do
    group = groups(:three_members)

    assert_changes "group.reload.owner.id", from: @user.id, to: users(:radperson).id do
      patch group_transfer_ownership_path(group, new_owner_id: users(:radperson).id), as: :turbo_stream
    end

    assert_redirected_to group
  end

  test "should update ownership of game proposal with turbo_stream" do
    game_proposal = game_proposals(:group_2_game_gta)

    assert_changes "game_proposal.reload.owner.id", from: @user.id, to: users(:radperson).id do
      patch game_proposal_transfer_ownership_path(game_proposal, new_owner_id: users(:radperson).id), as: :turbo_stream
    end

    assert_redirected_to game_proposal
  end

  test "should update ownership of game session with turbo_stream" do
    game_session = game_sessions(:group_3_game_thief_session_1)

    assert_changes "game_session.reload.owner.id", from: @user.id, to: users(:radperson).id do
      patch game_session_transfer_ownership_path(game_session, new_owner_id: users(:radperson).id), as: :turbo_stream
    end

    assert_redirected_to game_session
  end

  test "should not update ownership with invalid new_owner_id" do
    group = groups(:three_members)

    assert_no_changes "group.reload.owner.id" do
      patch group_transfer_ownership_path(group, new_owner_id: 0), as: :turbo_stream
    end
    assert_response :not_found
  end
end
