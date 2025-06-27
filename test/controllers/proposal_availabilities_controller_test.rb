require "test_helper"

class ProposalAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @proposal_availability = proposal_availabilities(:user_1_proposal_1_availability)
  end

  test "should get index" do
    sign_in_as users(:cooluserguy)
    get proposal_availabilities_url
    assert_response :success
  end

  test "should get new" do
    sign_in_as users(:cooluserguy)
    get new_game_proposal_proposal_availability_url(game_proposals(:group_2_game_2))
    assert_response :success
  end

  test "should create proposal_availability" do
    sign_in_as users(:cooluserguy)
    proposal = game_proposals(:group_2_game_2)
    assert_difference("ProposalAvailability.count") do
      post game_proposal_proposal_availabilities_url(proposal),
        params: {proposal_availability:
                   {availability_id: availabilities(:user_2_empty_availability).id,
                    user_id: @proposal_availability.user_id},
                 game_proposal_id: proposal.id}
    end

    assert_redirected_to game_proposal_url(proposal)
  end

  test "should show proposal_availability" do
    sign_in_as users(:admin)

    get proposal_availability_url(@proposal_availability)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as users(:admin)

    get edit_proposal_availability_url(@proposal_availability)
    assert_response :success
  end

  test "should update proposal_availability" do
    sign_in_as users(:admin)

    patch proposal_availability_url(@proposal_availability),
      params: {proposal_availability: {availability_id: availabilities(:user_1_empty_availability).id}}
    assert_redirected_to game_proposal_url(@proposal_availability.game_proposal)
  end

  test "should destroy proposal_availability" do
    sign_in_as users(:admin)

    assert_difference("ProposalAvailability.count", -1) do
      delete proposal_availability_url(@proposal_availability)
    end

    assert_redirected_to game_proposal_url(@proposal_availability.game_proposal)
  end
end
