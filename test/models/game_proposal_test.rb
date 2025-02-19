require "test_helper"

class GameProposalTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "no_votes returns proposal_votes where yes_vote is false" do
    game_proposal = game_proposals(:group_2_game_2)
    vote = proposal_votes(:proposal_2_user_3_no_vote)

    assert_equal [vote], game_proposal.no_votes
  end

  test "yes_votes returns proposal_votes where yes_vote is true" do
    game_proposal = game_proposals(:group_2_game_2)
    vote = proposal_votes(:proposal_2_user_2_yes_vote)

    assert_equal [vote], game_proposal.yes_votes
  end

  test "make_calendar_schedule returns a valid calendar schedule" do
    start_time = Time.new(2000, 1, 1, 0, 0, 0, "+00:00")
    end_time = start_time + 1.hour
    schedule = Schedule.new(name: "Test Schedule", start_time: start_time, end_time: end_time, duration: 1.hour, user_id: @user.id)
    valid_calendar_schedule = {start_time: {time: start_time.utc, zone: start_time.zone},
                               end_time: {time: end_time.utc, zone: end_time.zone},
                               name: "Test Schedule",
                               duration: 1.hour,
                               user_id: @user.id,
                               id: nil,
                               extimes: [],
                               rtimes: [],
                               rrules: [],
                               cal_rrule: "DTSTART:20000101T000000Z\nDTEND:20000101T010000Z",
                               selectable: true}
    assert_equal schedule.make_calendar_schedule, valid_calendar_schedule
  end

  test "make_calendar_schedules returns empty array when no game sessions exist" do
    game_proposal = game_proposals(:group_2_game_2)
    game_proposal.game_sessions.destroy_all

    assert_empty game_proposal.make_calendar_schedules
  end

  test "make_calendar_schedules returns calendar schedules only for sessions in range" do
    game_proposal = game_proposals(:group_3_game_1)
    session1 = GameSession.create(game_proposal: game_proposal, date: Time.new("2524-01-01 10:00:00"), duration: 1.hour)
    session2 = GameSession.create(game_proposal: game_proposal, date: Time.new("2524-01-02 10:00:00"), duration: 1.hour)
    GameSession.create(game_proposal: game_proposal, date: Time.new("2524-01-03 10:00:00"), duration: 1.hour)

    valid_calendar_schedule1 = {start_time: {time: session1.date.utc, zone: session1.date.zone},
                                end_time: {time: session1.date.utc + session1.duration, zone: session1.date.zone},
                                rrules: [],
                                rtimes: [],
                                extimes: [],
                                id: session1.id,
                                name: session1.game_name,
                                duration: session1.duration,
                                user_id: @user.id,
                                selectable: true}
    valid_calendar_schedule2 = {start_time: {time: session2.date.utc, zone: session2.date.zone},
                                end_time: {time: session2.date.utc + session2.duration, zone: session2.date.zone},
                                rrules: [],
                                rtimes: [],
                                extimes: [],
                                id: session2.id,
                                name: session2.game_name,
                                duration: session2.duration,
                                user_id: @user.id,
                                selectable: true}
    mock = Minitest::Mock.new
    mock.expect(:take, @user)
    mock.expect(:take, @user)
    mock.expect(:take, @user)

    User.stub :with_role, mock do
      result = game_proposal.make_calendar_schedules(start_time: session1.date.utc, end_time: session2.date.utc)
      assert_equal [valid_calendar_schedule1, valid_calendar_schedule2], result
    end
  end

  test "user_voted? returns true if the user has voted" do
    game_proposal = game_proposals(:group_2_game_2)
    user = users(:two)

    assert game_proposal.user_voted?(user)
  end

  test "user_voted? returns false if the user has not voted" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)

    assert_not game_proposal.user_voted?(user)
  end

  test "user_voted_yes_or_no? returns true if the user has voted yes or no" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)
    ProposalVote.create(user: user, game_proposal: game_proposal, yes_vote: true)

    assert game_proposal.user_voted_yes_or_no?(user)

    game_proposal.proposal_votes.find_by(user: user).update(yes_vote: false)
    assert game_proposal.user_voted_yes_or_no?(user)
  end

  test "user_voted_yes_or_no? returns false if the user has not voted yes or no" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)

    assert_not game_proposal.user_voted_yes_or_no?(user)
  end

  test "user_voted_yes? returns true if the user has voted yes" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)
    ProposalVote.create(user: user, game_proposal: game_proposal, yes_vote: true)

    assert game_proposal.user_voted_yes?(user)
  end

  test "user_voted_yes? returns false if the user has not voted yes" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)

    assert_not game_proposal.user_voted_yes?(user)

    ProposalVote.create(user: user, game_proposal: game_proposal, yes_vote: false)
    assert_not game_proposal.user_voted_yes?(user)
  end

  test "user_voted_no? returns true if the user has voted no" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)

    ProposalVote.create(user: user, game_proposal: game_proposal, yes_vote: false)
    assert game_proposal.user_voted_no?(user)
  end

  test "user_voted_no? returns false if the user has not voted no" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)

    assert_not game_proposal.user_voted_no?(user)

    ProposalVote.create(user: user, game_proposal: game_proposal, yes_vote: true)
    assert_not game_proposal.user_voted_no?(user)
  end

  test "update_vote_counts! updates yes_votes_count and no_votes_count" do
    game_proposal = game_proposals(:group_2_game_2)
    vote2 = proposal_votes(:proposal_2_user_3_no_vote)

    assert_equal 1, game_proposal.yes_votes_count
    assert_equal 1, game_proposal.no_votes_count
    vote2.update(yes_vote: true)

    game_proposal.update_vote_counts!

    assert_equal 2, game_proposal.yes_votes_count
    assert_equal 0, game_proposal.no_votes_count
  end

  test "get_user_proposal_availability returns the user's proposal availability" do
    game_proposal = game_proposals(:group_1_game_1)
    user = users(:admin)
    availability = proposal_availabilities(:user_1_proposal_1_availability)

    assert_equal availability, game_proposal.get_user_proposal_availability(user)
  end

  test "get_user_proposal_availability returns nil if the user has no proposal availability" do
    game_proposal = game_proposals(:group_2_game_2)
    user = users(:two)

    assert_nil game_proposal.get_user_proposal_availability(user)
  end

  test "user_get_or_build_vote returns the user's vote if it exists" do
    game_proposal = game_proposals(:group_2_game_2)
    user = users(:two)
    vote = proposal_votes(:proposal_2_user_2_yes_vote)

    assert_equal vote, game_proposal.user_get_or_build_vote(user)
  end

  test "user_get_or_build_vote builds a new vote if it doesn't exist" do
    game_proposal = game_proposals(:group_3_game_1)
    user = users(:two)

    vote = game_proposal.user_get_or_build_vote(user)

    assert vote.new_record?
    assert_equal user.id, vote.user_id
  end
end
