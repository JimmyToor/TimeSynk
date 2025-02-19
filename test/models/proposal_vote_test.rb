require "test_helper"

class ProposalVoteTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "should update proposal vote counts after update" do
    game_proposal = game_proposals(:group_2_game_2)
    vote1 = proposal_votes(:proposal_2_user_2_yes_vote)

    assert_equal 1, game_proposal.yes_votes.count
    assert_equal 1, game_proposal.no_votes.count

    vote1.update!(yes_vote: false)
    assert_equal 0, game_proposal.yes_votes.count
    assert_equal 2, game_proposal.no_votes.count
  end

  test "should update game proposal vote count after delete" do
    game_proposal = game_proposals(:group_2_game_2)
    vote1 = proposal_votes(:proposal_2_user_2_yes_vote)

    assert_equal 1, game_proposal.yes_votes.count
    assert_equal 1, game_proposal.no_votes.count

    vote1.destroy

    assert_equal 0, game_proposal.yes_votes.count
    assert_equal 1, game_proposal.no_votes.count
  end

  test "should update game proposal vote count after create" do
    game_proposal = game_proposals(:group_2_game_2)

    assert_equal 1, game_proposal.yes_votes.count
    assert_equal 1, game_proposal.no_votes.count

    ProposalVote.create!(user: @user, game_proposal: game_proposal, yes_vote: true)

    assert_equal 2, game_proposal.yes_votes.count
    assert_equal 1, game_proposal.no_votes.count
  end

  test "should reject duplicate votes" do
    vote1 = proposal_votes(:proposal_2_user_2_yes_vote)
    game_proposal = vote1.game_proposal

    assert_raises(ActiveRecord::RecordInvalid) do
      ProposalVote.create!(user: vote1.user, game_proposal: game_proposal, yes_vote: true)
    end
  end
end
