require "test_helper"

class SessionAttendancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_session_attendance = game_session_attendances(:one)
  end

  test "should get index" do
    get game_session_attendances_url
    assert_response :success
  end

  test "should get new" do
    get new_game_session_attendance_url
    assert_response :success
  end

  test "should create game_session_attendance" do
    assert_difference("SessionAttendance.count") do
      post game_session_attendances_url, params: { game_session_attendance: { attending: @game_session_attendance.attending, game_session_id: @game_session_attendance.game_session_id, user_id: @game_session_attendance.user_id } }
    end

    assert_redirected_to game_session_attendance_url(GameSessionAttendance.last)
  end

  test "should show game_session_attendance" do
    get game_session_attendance_url(@game_session_attendance)
    assert_response :success
  end

  test "should get edit" do
    get edit_game_session_attendance_url(@game_session_attendance)
    assert_response :success
  end

  test "should update game_session_attendance" do
    patch game_session_attendance_url(@game_session_attendance), params: { game_session_attendance: { attending: @game_session_attendance.attending, game_session_id: @game_session_attendance.game_session_id, user_id: @game_session_attendance.user_id } }
    assert_redirected_to game_session_attendance_url(@game_session_attendance)
  end

  test "should destroy game_session_attendance" do
    assert_difference("GameSessionAttendance.count", -1) do
      delete game_session_attendance_url(@game_session_attendance)
    end

    assert_redirected_to game_session_attendances_url
  end
end
