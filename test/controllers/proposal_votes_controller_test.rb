require "test_helper"

class ProposalVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @proposal_vote = proposal_votes(:one)
  end

  test "should get index" do
    get proposal_votes_url
    assert_response :success
  end

  test "should get new" do
    get new_proposal_vote_url
    assert_response :success
  end

  test "should create proposal_vote" do
    assert_difference("ProposalVote.count") do
      post proposal_votes_url, params: { proposal_vote: { comment: @proposal_vote.comment, game_proposal_id: @proposal_vote.proposal_id, user_id: @proposal_vote.user_id, yes_vote: @proposal_vote.yes_vote } }
    end

    assert_redirected_to proposal_vote_url(ProposalVote.last)
  end

  test "should show proposal_vote" do
    get proposal_vote_url(@proposal_vote)
    assert_response :success
  end

  test "should get edit" do
    get edit_proposal_vote_url(@proposal_vote)
    assert_response :success
  end

  test "should update proposal_vote" do
    patch proposal_vote_url(@proposal_vote), params: { proposal_vote: { comment: @proposal_vote.comment, game_proposal_id: @proposal_vote.proposal_id, user_id: @proposal_vote.user_id, yes_vote: @proposal_vote.yes_vote } }
    assert_redirected_to proposal_vote_url(@proposal_vote)
  end

  test "should destroy proposal_vote" do
    assert_difference("ProposalVote.count", -1) do
      delete proposal_vote_url(@proposal_vote)
    end

    assert_redirected_to proposal_votes_url
  end
end
