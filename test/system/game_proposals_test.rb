require "application_system_test_case"

class GameProposalsTest < ApplicationSystemTestCase
  setup do
    @user = users(:radperson)
    sign_in_as @user
  end

  test "visiting the index" do
    visit game_proposals_url

    count = @user.game_proposals.count

    assert_selector "h2", text: I18n.t("game_proposal.title")
    assert_selector "h3", count: count
  end

  test "should create game proposal" do
    group = groups(:three_members_0_proposals)
    game = games(:thief)

    visit group_url(group)
    click_on I18n.t("group.creation_dropdown.button_title", game_name: game.name)
    click_on I18n.t("game_proposal.new.button_text")

    find_button("select-game-#{game.id}").click

    accept_confirm do
      find_button(I18n.t("game_proposal.new.submit_text")).click
    end

    assert_current_path %r{/game_proposals/\d+}, ignore_query: true

    assert_selector("h3", text: game.name)
  end

  test "should not create game proposal for game already proposed" do
    group = groups(:three_members)
    game = games(:thief)

    visit group_game_proposals_url(group)
    click_on I18n.t("game_proposal.new.button_text")

    select group.name, from: "game_proposal_group_id"

    fill_in "query", with: game.name
    find_button("Search").click

    find_button("select-game-#{game.id}").click

    accept_confirm do
      click_on I18n.t("game_proposal.new.submit_text")
    end

    assert_text I18n.t("game_proposal.create.error", game_name: game.name)
  end

  test "should delete game proposal" do
    game_proposal = game_proposals(:group_3_game_thief)

    visit game_proposal_url(game_proposal)

    find("#game_proposal_#{game_proposal.id}_misc_dropdown_button").click

    click_on I18n.t("game_proposal.destroy.button_text")

    fill_in I18n.t("game_proposal.destroy.confirm_name"), with: game_proposal.game_name
    check I18n.t("game_proposal.destroy.confirm")

    within "#modal_confirmation_game_proposal_#{game_proposal.id}" do
      find_button(I18n.t("generic.delete")).click
    end

    assert_text I18n.t("game_proposal.destroy.success", game_name: game_proposal.game_name)
  end
end
