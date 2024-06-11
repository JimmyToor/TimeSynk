require "application_system_test_case"

class ProposalVotesTest < ApplicationSystemTestCase
  setup do
    @proposal_vote = proposal_votes(:one)
  end

  test "visiting the index" do
    visit proposal_votes_url
    assert_selector "h1", text: "Proposal votes"
  end

  test "should create proposal vote" do
    visit proposal_votes_url
    click_on "New proposal vote"

    fill_in "Comment", with: @proposal_vote.comment
    fill_in "Proposal", with: @proposal_vote.proposal_id
    fill_in "User", with: @proposal_vote.user_id
    check "Yes vote" if @proposal_vote.yes_vote
    click_on "Create Proposal vote"

    assert_text "Proposal vote was successfully created"
    click_on "Back"
  end

  test "should update Proposal vote" do
    visit proposal_vote_url(@proposal_vote)
    click_on "Edit this proposal vote", match: :first

    fill_in "Comment", with: @proposal_vote.comment
    fill_in "Proposal", with: @proposal_vote.proposal_id
    fill_in "User", with: @proposal_vote.user_id
    check "Yes vote" if @proposal_vote.yes_vote
    click_on "Update Proposal vote"

    assert_text "Proposal vote was successfully updated"
    click_on "Back"
  end

  test "should destroy Proposal vote" do
    visit proposal_vote_url(@proposal_vote)
    click_on "Destroy this proposal vote", match: :first

    assert_text "Proposal vote was successfully destroyed"
  end
end
