require "test_helper"

class ProposalVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @proposal_vote = proposal_votes(:group_2_game_gta_user_cooluserguy_yes)
    @game_proposal = @proposal_vote.game_proposal
    @user = @proposal_vote.user
    sign_in_as(@user)
  end

  test "should get new" do
    get new_game_proposal_proposal_vote_url(@game_proposal)
    assert_response :success
  end

  test "should not create proposal_vote when one exists" do
    game_proposal = game_proposals(:group_2_game_thief)
    assert_no_difference("ProposalVote.count") do
      post game_proposal_proposal_votes_url(game_proposal), params: {proposal_vote: {game_proposal_id: game_proposal.id, user_id: @user.id, yes_vote: true}}
    end
  end

  test "should show proposal_vote" do
    get proposal_vote_url(@proposal_vote)
    assert_response :success
  end

  test "should get edit" do
    get edit_proposal_vote_url(@proposal_vote)
    assert_response :success
  end

  test "should update yes-vote to no-vote" do
    old_vote_value = @proposal_vote.yes_vote
    patch proposal_vote_url(@proposal_vote), params: {proposal_vote: {comment: @proposal_vote.comment, game_proposal_id: @proposal_vote.game_proposal_id, user_id: @proposal_vote.user_id, yes_vote: false}}
    assert_not_equal @proposal_vote.reload.yes_vote, old_vote_value
  end

  test "should update yes-vote to undecided vote" do
    patch proposal_vote_url(@proposal_vote), params: {proposal_vote: {comment: @proposal_vote.comment, game_proposal_id: @proposal_vote.game_proposal_id, user_id: @proposal_vote.user_id, yes_vote: nil}}
    assert_nil @proposal_vote.reload.yes_vote
  end

  test "should destroy proposal_vote" do
    assert_difference("ProposalVote.count", -1) do
      delete proposal_vote_url(@proposal_vote)
    end
  end
end
