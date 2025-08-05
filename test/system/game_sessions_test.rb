require "application_system_test_case"

class GameSessionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:radperson)
    sign_in_as @user
  end

  test "visiting the index" do
    game_proposal = game_proposals(:group_3_game_thief)

    visit game_proposal_game_sessions_url(game_proposal)
    assert_selector "h2", text: I18n.t("game_session.upcoming.title_proposal", game_name: game_proposal.game_name, group_name: game_proposal.group_name)

    within "ul[aria-labelledby='upcoming_game_sessions']" do
      assert_selector "li", count: 2
    end
  end

  test "should create game session" do
    game_proposal = game_proposals(:group_3_game_thief)

    visit game_proposal_url(game_proposal)
    click_on I18n.t("game_proposal.creation_dropdown.button_title", game_name: game_proposal.game_name)
    click_on I18n.t("game_session.new.button_text")

    click_on I18n.t("game_session.new.submit_text")

    assert_text I18n.t("game_session.create.success", game_name: game_proposal.game_name)
    assert_selector "#game_session_#{GameSession.last.id}"
  end

  test "should update Game session" do
    game_proposal = game_proposals(:group_3_game_thief)

    game_session = game_sessions(:group_3_game_thief_session_2)
    visit game_proposal_game_sessions_url(game_proposal)
    find("##{dom_id(game_session, :link)}").click
    click_on I18n.t("game_session.edit.title", game_name: game_session.game_name, group_name: game_session.group_name)

    fill_in "game_session_duration_hours", with: 2
    click_on I18n.t("game_session.new.submit_text")

    assert_text I18n.t("game_session.update.success", game_name: game_proposal.game_name)
  end

  test "should destroy Game session" do
    game_proposal = game_proposals(:group_3_game_thief)

    game_session = game_sessions(:group_3_game_thief_session_2)
    visit game_proposal_game_sessions_url(game_proposal)
    find("##{dom_id(game_session, :link)}").click
    find_button(I18n.t("generic.delete")).click
    check I18n.t("game_session.destroy.confirm")
    click_on I18n.t("generic.delete")

    assert_text I18n.t("game_session.destroy.success", game_name: game_proposal.game_name)
  end
end
