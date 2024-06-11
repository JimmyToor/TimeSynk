require "application_system_test_case"

class GameProposalsTest < ApplicationSystemTestCase
  setup do
    @game_proposal = game_proposals(:one)
  end

  test "visiting the index" do
    visit game_proposals_url
    assert_selector "h1", text: "Game proposals"
  end

  test "should create game proposal" do
    visit game_proposals_url
    click_on "New game proposal"

    fill_in "Game checksum", with: @game_proposal.game_checksum
    fill_in "Group", with: @game_proposal.group_id
    fill_in "No votes", with: @game_proposal.no_votes
    fill_in "User", with: @game_proposal.user_id
    fill_in "Yes votes", with: @game_proposal.yes_votes
    click_on "Create Game proposal"

    assert_text "Game proposal was successfully created"
    click_on "Back"
  end

  test "should update Game proposal" do
    visit game_proposal_url(@game_proposal)
    click_on "Edit this game proposal", match: :first

    fill_in "Game checksum", with: @game_proposal.game_checksum
    fill_in "Group", with: @game_proposal.group_id
    fill_in "No votes", with: @game_proposal.no_votes
    fill_in "User", with: @game_proposal.user_id
    fill_in "Yes votes", with: @game_proposal.yes_votes
    click_on "Update Game proposal"

    assert_text "Game proposal was successfully updated"
    click_on "Back"
  end

  test "should destroy Game proposal" do
    visit game_proposal_url(@game_proposal)
    click_on "Destroy this game proposal", match: :first

    assert_text "Game proposal was successfully destroyed"
  end
end
