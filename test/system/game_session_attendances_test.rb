require "application_system_test_case"

class GameSessionAttendancesTest < ApplicationSystemTestCase
  setup do
    @game_session = game_sessions(:group_3_game_thief_session_2)
    @user = users(:radperson)
    sign_in_as @user
  end

  test "should view attendance list" do
    visit game_session_url(@game_session)

    attendance_list = find(".game_session_#{@game_session.id}_attendances")

    assert attendance_list.present?
    assert attendance_list.has_css?("&> div", count: @game_session.game_session_attendances.count)
  end

  test "should view attendance modal" do
    visit game_session_url(@game_session)

    click_on I18n.t("generic.attendance"), match: :first

    assert_selector "tbody tr th", count: @game_session.game_session_attendances.count
  end

  test "should view attendance details" do
    game_session_attendance = game_session_attendances(:group_3_game_thief_session_2_radperson)
    visit game_session_url(@game_session)

    attendance = find("div", id: "game_session_attendance_#{game_session_attendance.id}").find_button
    attendance.hover

    popover = find_by_id("popover_game_session_attendance_#{game_session_attendance.id}")
    assert popover.has_text?(I18n.t("game_session_attendance.values.unsure"))
  end

  test "should update Game session attendance" do
    game_proposal = @game_session.game_proposal

    visit game_proposal_game_sessions_url(game_proposal)
    find("##{dom_id(@game_session, :link)}").click

    choose I18n.t("game_session_attendance.values.attending")
    click_on I18n.t("game_session_attendance.edit.submit")

    assert_text I18n.t("game_session_attendance.update.success", game_name: game_proposal.game_name)
  end
end
