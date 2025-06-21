require "test_helper"

class GameProposalTest < ActiveSupport::TestCase
  test "no_votes returns proposal_votes where yes_vote is false" do
    game_proposal = game_proposals(:group_2_game_2)
    no_vote = proposal_votes(:proposal_2_user_3_no) # User 'three' has a no vote in fixtures

    assert_equal [no_vote], game_proposal.no_votes, "Should return only no votes"
  end

  test "yes_votes returns proposal_votes where yes_vote is true" do
    game_proposal = game_proposals(:group_2_game_2)
    yes_vote = proposal_votes(:proposal_2_user_2_yes) # User 'two' has a yes vote in fixtures

    assert_equal [yes_vote], game_proposal.yes_votes, "Should return only yes votes"
  end

  test "make_calendar_schedules returns empty array when no game sessions exist" do
    game_proposal = game_proposals(:group_2_game_2)
    game_proposal.game_sessions.destroy_all

    assert_empty game_proposal.make_calendar_schedules, "Should return empty array when no sessions exist"
  end

  test "make_calendar_schedules returns calendar schedules only for sessions in range" do
    game_proposal = game_proposals(:group_3_game_1)

    session2 = game_sessions(:proposal_3_session_2)
    session3 = game_sessions(:proposal_3_session_3)

    # Session 1 from fixtures (proposal_3_session_1) should be excluded by the range
    session_owner = users(:three)

    # Expected structure for session2 fixture
    valid_calendar_schedule2 = {
      start_time: {time: session2.date.utc, zone: session2.date.time_zone.name},
      end_time: {time: (session2.date + session2.duration).utc, zone: session2.date.time_zone.name},
      rrules: [],
      rtimes: [],
      extimes: [],
      id: session2.id,
      name: session2.game_name,
      duration: session2.duration,
      user_id: session_owner.id,
      selectable: true,
      group: session2.group_name
    }

    # Expected structure for session3 fixture
    valid_calendar_schedule3 = {
      start_time: {time: session3.date.utc, zone: session3.date.time_zone.name},
      end_time: {time: (session3.date + session3.duration).utc, zone: session3.date.time_zone.name},
      rrules: [],
      rtimes: [],
      extimes: [],
      id: session3.id,
      name: session3.game_name,
      duration: session3.duration,
      user_id: session_owner.id, # Assuming this is the expected user
      selectable: true,
      group: session3.group_name
    }

    result = game_proposal.make_calendar_schedules(start_time: session2.date, end_time: session3.date)

    # Convert result to set for comparison to ignore order
    assert_equal [valid_calendar_schedule2, valid_calendar_schedule3].to_set, result.to_set, "Should return only sessions 2 and 3 from fixtures within the specified range"
  end

  test "user_voted? returns true if the user has voted" do
    game_proposal = game_proposals(:group_2_game_2)
    voted_user = users(:two) # User 'two' has voted in fixtures

    assert game_proposal.user_voted?(voted_user), "Should return true for user who has voted"
  end

  test "user_voted? returns false if the user has not voted" do
    game_proposal = game_proposals(:group_1_game_1)
    non_voting_user = users(:two) # User 'two' has not voted on this proposal

    assert_not game_proposal.user_voted?(non_voting_user), "Should return false for user who has not voted"
  end

  test "user_voted_yes_or_no? returns true if the user has voted yes or no" do
    game_proposal = game_proposals(:group_3_game_1)
    undecided_user = users(:two) # User with initially undecided vote

    # Use existing undecided vote from fixtures
    vote = proposal_votes(:proposal_3_user_2_undecided)

    vote.update!(yes_vote: true)
    assert game_proposal.reload.user_voted?(undecided_user), "Should return true after voting yes"

    vote.update!(yes_vote: false)
    assert game_proposal.reload.user_voted?(undecided_user), "Should return true after voting no"

    vote.update!(yes_vote: nil)
    assert_not game_proposal.reload.user_voted?(undecided_user), "Should return false after unvoting"
  end

  test "user_voted_yes_or_no? returns false if the user has not voted" do
    game_proposal = game_proposals(:group_2_game_1)
    non_voting_user = users(:admin) # User 'admin' has no vote for this proposal

    # Ensure user admin actually has no vote for this proposal in fixtures
    assert_nil game_proposal.proposal_votes.find_by(user: non_voting_user)

    assert_not game_proposal.user_voted?(non_voting_user), "Should return false for user with no vote record"
  end

  test "user_voted_yes? returns true if the user has voted yes" do
    game_proposal = game_proposals(:group_2_game_2)
    yes_vote_user = users(:two) # User 'two' has a yes vote in fixtures

    assert game_proposal.user_voted_yes?(yes_vote_user), "Should return true for user with yes vote"
  end

  test "user_voted_yes? returns false if the user has not voted yes" do
    game_proposal = game_proposals(:group_2_game_2)
    no_vote_user = users(:three) # User 'three' has a no vote in fixtures
    no_vote_record_user = users(:admin) # User 'admin' has no vote record in fixtures

    assert_not game_proposal.user_voted_yes?(no_vote_user), "Should be false for user with no vote"
    assert_not game_proposal.user_voted_yes?(no_vote_record_user), "Should be false for user with no vote record"
  end

  test "user_voted_no? returns true if the user has voted no" do
    game_proposal = game_proposals(:group_2_game_2)
    no_vote_user = users(:three) # User 'three' has a no vote in fixtures

    assert game_proposal.user_voted_no?(no_vote_user), "Should return true for user with no vote"
  end

  test "user_voted_no? returns false if the user has not voted no" do
    game_proposal = game_proposals(:group_2_game_2)
    yes_vote_user = users(:two) # User 'two' has a yes vote in fixtures
    no_vote_record_user = users(:admin) # User 'admin' has no vote record in fixtures

    assert_not game_proposal.user_voted_no?(yes_vote_user), "Should be false for user with yes vote"
    assert_not game_proposal.user_voted_no?(no_vote_record_user), "Should be false for user with no vote record"
  end

  test "update_vote_counts! updates yes_votes_count and no_votes_count" do
    game_proposal = game_proposals(:group_2_game_2)
    vote_to_change = proposal_votes(:proposal_2_user_3_no) # User 'three' has a no vote in fixtures

    # Initial state from fixtures: user 2 voted yes, user 3 voted no

    vote_to_change.update!(yes_vote: true)

    game_proposal.update_vote_counts!

    # Verify counts reflect the change (both users voted yes)
    assert_equal 2, game_proposal.yes_votes_count, "Should have 2 yes votes after update"
    assert_equal 0, game_proposal.no_votes_count, "Should have 0 no votes after update"
  end

  test "get_user_proposal_availability returns the user's proposal availability" do
    game_proposal = game_proposals(:group_1_game_1)
    user_with_availability = users(:admin) # User 'admin' has availability for this proposal
    expected_availability = proposal_availabilities(:user_1_proposal_1_availability)

    assert_equal expected_availability, game_proposal.get_user_proposal_availability(user_with_availability),
      "Should return the user's associated availability"
  end

  test "get_user_proposal_availability returns nil if the user has no proposal availability" do
    game_proposal = game_proposals(:group_2_game_2)
    user_without_availability = users(:admin) # User 'admin' has no availability for this proposal

    assert_nil game_proposal.get_user_proposal_availability(user_without_availability),
      "Should return nil when user has no availability"
  end

  test "user_get_or_build_vote returns the user's vote if it exists" do
    game_proposal = game_proposals(:group_2_game_2)
    user_with_vote = users(:two) # User 'two' has a vote in fixtures
    expected_vote = proposal_votes(:proposal_2_user_2_yes)

    assert_equal expected_vote, game_proposal.user_get_or_build_vote(user_with_vote),
      "Should return the existing vote record"
  end

  test "user_get_or_build_vote returns a new vote if none exists" do
    game_proposal = game_proposals(:group_3_game_1)
    user_without_vote = users(:admin) # User 'admin' has no vote for this proposal

    vote = game_proposal.user_get_or_build_vote(user_without_vote)

    assert vote.new_record?, "Should be a new, unsaved record"
    assert_equal user_without_vote.id, vote.user_id, "Should be associated with the correct user"
    assert_equal game_proposal.id, vote.game_proposal_id, "Should be associated with the correct proposal"
  end
end
