require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_session = game_sessions(:three)
    @game_proposal = @game_session.game_proposal
    @group = @game_proposal.group
    @user = users(:three)
    sign_in_as(@user)
  end

  test "should get index" do
    get game_sessions_url
    assert_response :success
  end

  test "should get new" do
    get new_game_proposal_game_session_url @game_proposal
    assert_response :success
  end

  test "should create game_session" do
    assert_difference("GameSession.count") do
      post game_proposal_game_sessions_url @game_proposal, params: { game_session: { date: Time.now.utc, duration_hours: 1, duration_minutes: 10, game_proposal_id: @game_proposal.id } }
    end

    assert_redirected_to game_proposal_url(@game_proposal)
  end

  test "should show game_session" do
    get game_session_url(@game_session)
    assert_response :success
  end

  test "should get edit" do
    get edit_game_session_url(@game_session)
    assert_response :success
  end

  test "should update game_session" do
    patch game_session_url(@game_session), params: { game_session: { date: @game_session.date, duration_hours: 2, duration_minutes: 0, game_proposal_id: @game_session.game_proposal_id } }
    assert_redirected_to game_proposal_url(@game_session.game_proposal)
    assert_changes -> { @game_session.duration == 2.hours } do
      @game_session.reload
    end
  end

  test "should destroy game_session" do
    assert_difference("GameSession.count", -1) do
      delete game_session_url(@game_session)
    end

    assert_redirected_to @game_proposal
  end
end
