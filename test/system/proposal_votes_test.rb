require "application_system_test_case"

class ProposalVotesTest < ApplicationSystemTestCase
  setup do
    @user = users(:radperson)
    sign_in_as @user
  end

  test "should view proposal vote count" do
    game_proposal = game_proposals(:group_3_game_thief)
    visit game_proposal_url(game_proposal)

    vote_count = find("#vote_count_game_proposal_#{game_proposal.id}")

    assert vote_count.present?
    assert vote_count.has_css?("span", text: "Yes: 1")
    assert vote_count.has_css?("span", text: "No: 0")
    assert vote_count.has_css?("span", text: "Undecided: 2")
  end

  test "should view proposal vote list" do
    game_proposal = game_proposals(:group_3_game_thief)
    visit game_proposal_url(game_proposal)

    vote_list = find("#game_proposal_#{game_proposal.id}_votes")

    assert vote_list.has_css?("&> div", count: game_proposal.proposal_votes.count)
  end

  test "should view proposal vote modal" do
    game_proposal = game_proposals(:group_3_game_thief)
    visit game_proposal_url(game_proposal)

    click_on I18n.t("proposal_vote.index.button_title")

    assert_selector "tbody tr th", count: game_proposal.proposal_votes.count
  end

  test "should view proposal vote details" do
    game_proposal = game_proposals(:group_3_game_thief)
    proposal_vote = proposal_votes(:group_3_game_thief_user_radperson_undecided)
    visit game_proposal_url(game_proposal)

    vote = find("div", id: "proposal_vote_#{proposal_vote.id}").find_button
    vote.hover

    popover = find_by_id("popover_proposal_vote_#{proposal_vote.id}")
    assert popover.has_text?("Undecided")
  end

  test "should update Proposal vote" do
    game_proposal = game_proposals(:group_3_game_thief)
    proposal_vote = proposal_votes(:group_3_game_thief_user_radperson_undecided)
    visit game_proposal_url(game_proposal)

    click_on I18n.t("proposal_vote.edit.button_title", game_name: game_proposal.game_name, group_name: game_proposal.group_name)

    choose "Yes"
    fill_in "Comment", with: "This is a test comment."

    click_on I18n.t("proposal_vote.edit.submit_text")

    find("dialog").find_button.click

    assert_text I18n.t("proposal_vote.update.success")

    vote = find("div", id: "proposal_vote_#{proposal_vote.id}").find_button
    vote.hover

    popover = find_by_id("popover_proposal_vote_#{proposal_vote.id}")
    assert popover.has_text?("Yes")
  end
end
