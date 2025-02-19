require "test_helper"

class AvailabilitySchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    sign_in_as @user
    @availability_schedule = availability_schedules(:availability_2_schedule_3)
  end

  test "should get index" do
    get availability_schedules_url
    assert_response :success
  end

  test "should get index with query" do
    availability = schedules(:user_3_unique_name)
    get availability_schedules_url(format: :turbo_stream), params: {query: availability.name}
    assert_response :success
  end
end
