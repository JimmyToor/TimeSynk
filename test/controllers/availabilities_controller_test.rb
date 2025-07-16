require "test_helper"

class AvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @availability = availabilities(:user_cooluserguy_default_availability)
    @user = users(:cooluserguy)
    @schedule = schedules(:user_cooluserguy_default)
    sign_in_as @user
  end

  test "should get index" do
    get availabilities_url
    assert_response :success
  end

  test "should get new" do
    get new_availability_url
    assert_dom "h1", text: "New Availability"
  end

  test "should create empty availability" do
    assert_difference("Availability.count") do
      post availabilities_url, params: {availability: {user_id: @user.id, name: "new availability"}}
    end

    assert_redirected_to availability_url(Availability.last)
  end

  test "should create availability with schedules" do
    assert_difference("Availability.count") do
      schedule = Schedule.create(name: "new schedule", user: @user)
      schedule2 = Schedule.create(name: "new schedule2", user: @user)
      post availabilities_url, params: {availability: {user_id: @user.id, name: "new availability", availability_schedules_attributes: [{schedule_id: schedule.id}, {schedule_id: schedule2.id}]}}
    end

    assert_redirected_to availability_url(Availability.last)
  end

  test "should not create availability with invalid param (name)" do
    assert_no_difference("Availability.count") do
      post availabilities_url, params: {availability: {user_id: @user.id, name: ""}}
    end

    assert_response :unprocessable_entity
  end

  test "should show availability" do
    get availability_url(@availability)
    assert_response :success
  end

  test "should get edit" do
    get edit_availability_url(@availability)
    # assert that there is an input field with the value of the availability name
    assert_dom "input", value: @availability.name
  end

  test "should update availability" do
    patch availability_url(@availability), params: {availability: {user_id: @user.id, name: "updated name"}, id: @availability.id}
    assert_redirected_to availability_url(@availability)
  end

  test "should destroy availability" do
    assert_difference("Availability.count", -1) do
      delete availability_url(@availability)
    end

    assert_redirected_to availabilities_url
  end

  test "should search availabilities" do
    get availabilities_url, params: {query: @availability.name}
    assert_response :success
  end
end
