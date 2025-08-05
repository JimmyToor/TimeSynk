require "test_helper"

class GameProposalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_proposal = game_proposals(:group_3_game_thief)
    @user = users(:radperson)
    @group = groups(:three_members)
    sign_in_as @user
  end

  test "should get index" do
    get game_proposals_url
    assert_response :success
  end

  test "should get index with turbo_stream" do
    get game_proposals_url, as: :turbo_stream
    assert_response :success
  end

  test "should get new" do
    get new_group_game_proposal_url @group
    assert_response :success
  end

  test "should create game_proposal" do
    game = games(:link_to_the_past)
    assert_difference("GameProposal.count") do
      post group_game_proposals_url @group, params: {game_proposal: {game_id: game.id, group_id: @group.id}}
    end

    assert_redirected_to game_proposal_url(GameProposal.last)
  end

  test "should not create game_proposal for game with existing proposal" do
    game = games(:thief)
    post group_game_proposals_url(@group, params: {game_proposal: {game_id: game.id, group_id: @group.id}}, format: :turbo_stream)
    assert_response :unprocessable_entity
  end

  test "should show game_proposal" do
    get game_proposal_url(@game_proposal)
    assert_response :success
  end

  test "should show json game_proposal" do
    get game_proposal_url(@game_proposal, format: :json)
    assert_response :success
    assert_equal "application/json", @response.media_type
  end

  test "should destroy game_proposal" do
    assert_difference("GameProposal.count", -1) do
      delete game_proposal_url(@game_proposal)
    end

    assert_redirected_to game_proposals_url
  end
end
