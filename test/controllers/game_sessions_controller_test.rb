require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_session = game_sessions(:group_2_game_gta_session_1)
    @game_proposal = @game_session.game_proposal
    @group = @game_proposal.group
    @user = users(:cooluserguy)
    sign_in_as(@user)
  end

  test "should get index" do
    get game_proposal_game_sessions_url(@game_proposal)
    assert_response :success
  end

  test "should get index with turbo_stream" do
    get game_proposal_game_sessions_url(@game_proposal, format: :turbo_stream)
    assert_response :success
  end

  test "should get new" do
    get new_game_proposal_game_session_url(@game_proposal)
    assert_response :success
  end

  test "should create game_session" do
    assert_difference("GameSession.count") do
      post game_proposal_game_sessions_url(@game_proposal),
        params: {game_session: {date: Time.now.utc,
                                duration_hours: 1,
                                duration_minutes: 10,
                                game_proposal_id: @game_proposal.id}}
    end

    assert_redirected_to game_proposal_path(@game_proposal)
  end

  test "should create game_session with turbo_stream" do
    assert_difference("GameSession.count") do
      post game_proposal_game_sessions_url(@game_proposal, format: :turbo_stream),
        params: {game_session: {date: Time.now.utc,
                                duration_hours: 1,
                                duration_minutes: 10,
                                game_proposal_id: @game_proposal.id}}
    end

    assert_response :success
  end

  test "should not create game_session with invalid data" do
    assert_no_difference("GameSession.count") do
      post game_proposal_game_sessions_url(@game_proposal),
        params: {game_session: {date: nil, duration_hours: 0, duration_minutes: 0, duration_days: 1, game_proposal_id: @game_proposal.id}}
    end

    assert_response :unprocessable_entity
    assert_not_nil flash.now[:error]
  end

  test "should show game_session" do
    get game_session_url(@game_session)
    assert_response :success
  end

  test "should get edit" do
    get edit_game_session_url(@game_session)
    assert_response :success
  end

  test "should update game_session with turbo_stream" do
    assert_changes -> { @game_session.duration == 2.hours } do
      patch game_session_url(@game_session, format: :turbo_stream),
        params: {game_session: {date: @game_session.date,
                                duration_hours: 2,
                                duration_minutes: 0,
                                game_proposal_id: @game_session.game_proposal_id}}
      @game_session.reload
    end
    assert_response :success
  end

  test "should destroy game_session" do
    assert_difference("GameSession.count", -1) do
      delete game_session_url(@game_session, format: :turbo_stream)
    end

    assert_response :success
  end

  test "should not show non-existent game session" do
    get game_session_url(id: "non-existent")
    assert_response :not_found
    assert_not_nil flash.now[:error]
  end
end
