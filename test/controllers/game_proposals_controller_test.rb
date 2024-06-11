require "test_helper"

class GameProposalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_proposal = game_proposals(:one)
  end

  test "should get index" do
    get game_proposals_url
    assert_response :success
  end

  test "should get new" do
    get new_game_proposal_url
    assert_response :success
  end

  test "should create game_proposal" do
    assert_difference("GameProposal.count") do
      post game_proposals_url, params: { game_proposal: { game_checksum: @game_proposal.game_checksum, group_id: @game_proposal.group_id, no_votes: @game_proposal.no_votes, user_id: @game_proposal.user_id, yes_votes: @game_proposal.yes_votes } }
    end

    assert_redirected_to game_proposal_url(GameProposal.last)
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
    patch game_proposal_url(@game_proposal), params: { game_proposal: { game_checksum: @game_proposal.game_checksum, group_id: @game_proposal.group_id, no_votes: @game_proposal.no_votes, user_id: @game_proposal.user_id, yes_votes: @game_proposal.yes_votes } }
    assert_redirected_to game_proposal_url(@game_proposal)
  end

  test "should destroy game_proposal" do
    assert_difference("GameProposal.count", -1) do
      delete game_proposal_url(@game_proposal)
    end

    assert_redirected_to game_proposals_url
  end
end
