require "test_helper"

class AvailabilitySchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @availability_schedule = availability_schedules(:one)
  end

  test "should get index" do
    get availability_schedules_url
    assert_response :success
  end

  test "should get new" do
    get new_availability_schedule_url
    assert_response :success
  end

  test "should create availability_schedule" do
    assert_difference("AvailabilitySchedule.count") do
      post availability_schedules_url, params: { availability_schedule: { availability_id: @availability_schedule.availability_id, schedule_id: @availability_schedule.schedule_id } }
    end

    assert_redirected_to availability_schedule_url(AvailabilitySchedule.last)
  end

  test "should show availability_schedule" do
    get availability_schedule_url(@availability_schedule)
    assert_response :success
  end

  test "should get edit" do
    get edit_availability_schedule_url(@availability_schedule)
    assert_response :success
  end

  test "should update availability_schedule" do
    patch availability_schedule_url(@availability_schedule), params: { availability_schedule: { availability_id: @availability_schedule.availability_id, schedule_id: @availability_schedule.schedule_id } }
    assert_redirected_to availability_schedule_url(@availability_schedule)
  end

  test "should destroy availability_schedule" do
    assert_difference("AvailabilitySchedule.count", -1) do
      delete availability_schedule_url(@availability_schedule)
    end

    assert_redirected_to availability_schedules_url
  end
end
