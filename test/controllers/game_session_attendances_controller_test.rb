require "test_helper"

class GameSessionAttendancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_session_attendance = game_session_attendances(:proposal_3_session_2_cooluserguy)
    @user = users(:cooluserguy)
    sign_in_as(@user)
  end

  test "should get index" do
    get game_session_game_session_attendances_url(game_session_id: @game_session_attendance.game_session.id), params: {format: :turbo_stream}
    assert_response :success
  end

  test "should get index with query" do
    get game_session_game_session_attendances_url(@game_session_attendance.game_session), params: {format: :turbo_stream, query: "test"}
    assert_response :success
  end

  test "should update game session attendance" do
    patch game_session_attendance_url(@game_session_attendance), params: {format: :turbo_stream, game_session_attendance: {attending: true}}
    assert_response :success
  end
end
