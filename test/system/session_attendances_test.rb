require "application_system_test_case"

class SessionAttendancesTest < ApplicationSystemTestCase
  setup do
    @game_session_attendance = game_session_attendances(:one)
  end

  test "visiting the index" do
    visit game_session_attendances_url
    assert_selector "h1", text: "Game session attendances"
  end

  test "should create game session attendance" do
    visit game_session_attendances_url
    click_on "New game session attendance"

    check "Attending" if @game_session_attendance.attending
    fill_in "Game session", with: @game_session_attendance.game_session_id
    fill_in "User", with: @game_session_attendance.user_id
    click_on "Create Game session attendance"

    assert_text "Game session attendance was successfully created"
    click_on "Back"
  end

  test "should update Game session attendance" do
    visit game_session_attendance_url(@game_session_attendance)
    click_on "Edit this game session attendance", match: :first

    check "Attending" if @game_session_attendance.attending
    fill_in "Game session", with: @game_session_attendance.game_session_id
    fill_in "User", with: @game_session_attendance.user_id
    click_on "Update Game session attendance"

    assert_text "Game session attendance was successfully updated"
    click_on "Back"
  end

  test "should destroy Game session attendance" do
    visit game_session_attendance_url(@game_session_attendance)
    click_on "Destroy this game session attendance", match: :first

    assert_text "Game session attendance was successfully destroyed"
  end
end
