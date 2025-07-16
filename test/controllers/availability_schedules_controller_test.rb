require "test_helper"

class AvailabilitySchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:cooluserguy)
    sign_in_as @user
    @availability_schedule = availability_schedules(:availability_cooluserguy_default_schedule_1)
  end

  test "should get json index" do
    get availability_schedules_url(format: :json, params: {availability_id: @availability_schedule.availability.id})
    assert_response :success
  end

  test "should get json index with query" do
    availability = schedules(:user_radperson_unique_name)
    get availability_schedules_url(format: :json), params: {query: availability.name}
    assert_response :success
  end
end
