require "test_helper"

class GameProposalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_proposal = game_proposals(:three)
    @user = users(:three)
    @group = groups(:three_members)
    sign_in_as @user
  end

  test "should get index" do
    get game_proposals_url
    assert_response :success
  end

  test "should get new" do
    get new_group_game_proposal_url @group
    assert_response :success
  end

  test "should create game_proposal" do
    assert_difference("GameProposal.count") do
      post group_game_proposals_url @group, params: { game_proposal: { game_id: 5, group_id: @group.id} }
    end

    assert_redirected_to game_proposal_url(GameProposal.last)
  end

  test "should not create game_proposal for game with existing proposal" do
    post group_game_proposals_url @group, params: { game_proposal: { game_id: 1, group_id: @group.id} }
    assert_response :unprocessable_entity
  end

  test "should show game_proposal" do
    get game_proposal_url(@game_proposal)
    assert_response :success
  end

  test "should get edit" do
    get edit_game_proposal_url(@game_proposal)
    assert_response :success
  end

  test "should update game_proposal" do
    patch game_proposal_url(@game_proposal), params: { game_proposal: { game_id: @game_proposal.game_id, group_id: @game_proposal.group_id} }
    assert_redirected_to game_proposal_url(@game_proposal)
  end

  test "should destroy game_proposal" do
    assert_difference("GameProposal.count", -1) do
      delete game_proposal_url(@game_proposal)
    end

    assert_redirected_to game_proposals_url
  end
end
