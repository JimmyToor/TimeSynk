require "test_helper"

class ProposalAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @proposal_availability = proposal_availabilities(:one)
  end

  test "should get index" do
    get proposal_availabilities_url
    assert_response :success
  end

  test "should get new" do
    get new_proposal_availability_url
    assert_response :success
  end

  test "should create proposal_availability" do
    assert_difference("ProposalAvailability.count") do
      post proposal_availabilities_url, params: { proposal_availability: { game_proposal_id: @proposal_availability.proposal_id, schedule_id: @proposal_availability.schedule_id, user_id: @proposal_availability.user_id } }
    end

    assert_redirected_to proposal_availability_url(ProposalAvailability.last)
  end

  test "should show proposal_availability" do
    get proposal_availability_url(@proposal_availability)
    assert_response :success
  end

  test "should get edit" do
    get edit_proposal_availability_url(@proposal_availability)
    assert_response :success
  end

  test "should update proposal_availability" do
    patch proposal_availability_url(@proposal_availability), params: { proposal_availability: { game_proposal_id: @proposal_availability.proposal_id, schedule_id: @proposal_availability.schedule_id, user_id: @proposal_availability.user_id } }
    assert_redirected_to proposal_availability_url(@proposal_availability)
  end

  test "should destroy proposal_availability" do
    assert_difference("ProposalAvailability.count", -1) do
      delete proposal_availability_url(@proposal_availability)
    end

    assert_redirected_to proposal_availabilities_url
  end
end
