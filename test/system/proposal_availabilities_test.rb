require "application_system_test_case"

class ProposalAvailabilitiesTest < ApplicationSystemTestCase
  setup do
    @proposal_availability = proposal_availabilities(:one)
  end

  test "visiting the index" do
    visit proposal_availabilities_url
    assert_selector "h1", text: "Proposal availabilities"
  end

  test "should create proposal availability" do
    visit proposal_availabilities_url
    click_on "New proposal availability"

    fill_in "Proposal", with: @proposal_availability.proposal_id
    fill_in "Schedule", with: @proposal_availability.schedule_id
    fill_in "User", with: @proposal_availability.user_id
    click_on "Create Proposal availability"

    assert_text "Proposal availability was successfully created"
    click_on "Back"
  end

  test "should update Proposal availability" do
    visit proposal_availability_url(@proposal_availability)
    click_on "Edit this proposal availability", match: :first

    fill_in "Proposal", with: @proposal_availability.proposal_id
    fill_in "Schedule", with: @proposal_availability.schedule_id
    fill_in "User", with: @proposal_availability.user_id
    click_on "Update Proposal availability"

    assert_text "Proposal availability was successfully updated"
    click_on "Back"
  end

  test "should destroy Proposal availability" do
    visit proposal_availability_url(@proposal_availability)
    click_on "Destroy this proposal availability", match: :first

    assert_text "Proposal availability was successfully destroyed"
  end
end
