require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = schedules(:user_2_default)
    @user = users(:two)
    sign_in_as @user
  end

  test "should get index" do
    get schedules_url
    assert_response :success
  end

  test "should get index with query" do
    get schedules_url(format: :turbo_stream, params: {query: "Single Hour"})
    assert_response :success
    schedules = assigns(:schedules)
    assert schedules.size == 1
    assert schedules.all? { |s| s.name.include?("Single Hour") }
  end

  test "should get new" do
    get new_schedule_url
    assert_response :success
  end

  test "should create schedule" do
    assert_difference("Schedule.count") do
      post schedules_url, params: {schedule: {user_id: @user.id, name: "newschedulezzz", duration: @schedule.duration, end_time: @schedule.end_time, schedule_pattern: {}, start_time: @schedule.start_time}}
    end

    assert_redirected_to schedule_url(Schedule.last)
  end

  test "should show schedule" do
    get schedule_url(@schedule)
    assert_response :success
  end

  test "should get edit" do
    get edit_schedule_url(@schedule)
    assert_response :success
  end

  test "should update schedule" do
    patch schedule_url(@schedule), params: {schedule: {duration: @schedule.duration, end_time: @schedule.end_time, schedule_pattern: @schedule.schedule_pattern, start_time: @schedule.start_time}}
    assert_redirected_to schedule_url(@schedule)
  end

  test "should destroy schedule" do
    assert_difference("Schedule.count", -1) do
      delete schedule_url(@schedule)
    end

    assert_redirected_to schedules_url
  end
end
