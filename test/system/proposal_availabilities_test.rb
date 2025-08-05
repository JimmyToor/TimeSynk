require "application_system_test_case"

class ProposalAvailabilitiesTest < ApplicationSystemTestCase
  setup do
    @user = sign_in_as(users(:cooluserguy))
  end

  test "should update Proposal Availability" do
    proposal = game_proposals(:group_3_game_thief)

    visit game_proposal_url(proposal)
    click_on "game_proposal_#{proposal.id}_misc_dropdown_button"
    click_on I18n.t("proposal_availability.edit.button_text")

    availability = availabilities(:user_cooluserguy_default_availability)
    select availability.name
    click_on I18n.t("proposal_availability.edit.submit_text")

    assert_text I18n.t("proposal_availability.update.success", availability_name: availability.name)
  end

  test "should create Proposal Availability" do
    proposal = game_proposals(:group_3_game_gta)

    visit game_proposal_url(proposal)
    click_on "game_proposal_#{proposal.id}_misc_dropdown_button"
    click_on I18n.t("proposal_availability.new.button_text")

    availability = availabilities(:user_cooluserguy_empty_availability)
    select availability.name
    click_on I18n.t("proposal_availability.edit.submit_text")

    assert_text I18n.t("proposal_availability.update.success", availability_name: availability.name)
  end

  test "should destroy Proposal Availability" do
    proposal = game_proposals(:group_3_game_thief)

    visit game_proposal_url(proposal)
    click_on "game_proposal_#{proposal.id}_misc_dropdown_button"
    click_on I18n.t("proposal_availability.edit.button_text")

    accept_confirm do
      click_on I18n.t("proposal_availability.destroy.submit_text")
    end

    assert_text I18n.t("proposal_availability.destroy.success", game_name: proposal.game_name)
  end
end
