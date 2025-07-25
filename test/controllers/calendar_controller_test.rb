require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:cooluserguy)
    sign_in_as(@user)
  end

  test "should get new" do
    get calendars_new_url
    assert_response :success
  end

  test "should get calendars as JSON" do
    schedule1 = schedules(:user_cooluserguy_single_hour)
    get calendars_url(format: :json, params: {schedule_id: schedule1.id})

    # not mocked because the test is about the response matching this output
    service = CalendarCreationService.new(ActionController::Parameters.new(schedule_id: schedule1.id), @user)

    assert_response :success
    assert_equal "application/json", @response.media_type
    assert_equal JSON.parse(service.call.to_json), JSON.parse(@response.body)
  end

  test "should not get calendar with unauthorized group" do
    group = groups(:one_member)
    get calendars_url(format: :json, params: {group_id: group.id})

    assert_response :unauthorized
  end
end
