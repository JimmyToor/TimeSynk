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

  test "should get index with search query" do
    get availabilities_url, params: {query: @availability.name}
    assert_response :success
  end

  test "should get turbo_stream index with search query" do
    get availabilities_url, params: {query: @availability.name, format: :turbo_stream}
    assert_response :success
  end

  test "should get new" do
    get new_availability_url
    assert_response :success
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
      post availabilities_url(format: :turbo_stream), params: {availability: {user_id: @user.id, name: ""}}
    end

    assert_response :unprocessable_entity
  end

  test "should show availability" do
    get availability_url(@availability)
    assert_response :success
  end

  test "should get edit" do
    get edit_availability_url(@availability)
    assert_response :success
  end

  test "should update availability" do
    old_name = @availability.name
    new_name = "#{old_name} updated"

    assert_changes "@availability.reload.name", from: old_name, to: new_name do
      patch availability_url(@availability, format: :turbo_stream), params: {availability: {user_id: @user.id, name: new_name}, id: @availability.id}
    end

    assert_redirected_to availability_url(@availability)
  end

  test "should destroy availability" do
    assert_difference("Availability.count", -1) do
      delete availability_url(@availability)
    end

    assert_redirected_to availabilities_url
  end
end
