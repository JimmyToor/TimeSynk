require "application_system_test_case"

class AvailabilitySchedulesTest < ApplicationSystemTestCase
  setup do
    @availability_schedule = availability_schedules(:one)
  end

  test "visiting the index" do
    visit availability_schedules_url
    assert_selector "h1", text: "Availability schedules"
  end

  test "should create availability schedule" do
    visit availability_schedules_url
    click_on "New availability schedule"

    fill_in "Availability", with: @availability_schedule.availability_id
    fill_in "Schedule", with: @availability_schedule.schedule_id
    click_on "Create Availability schedule"

    assert_text "Availability schedule was successfully created"
    click_on "Back"
  end

  test "should update Availability schedule" do
    visit availability_schedule_url(@availability_schedule)
    click_on "Edit this availability schedule", match: :first

    fill_in "Availability", with: @availability_schedule.availability_id
    fill_in "Schedule", with: @availability_schedule.schedule_id
    click_on "Update Availability schedule"

    assert_text "Availability schedule was successfully updated"
    click_on "Back"
  end

  test "should destroy Availability schedule" do
    visit availability_schedule_url(@availability_schedule)
    click_on "Destroy this availability schedule", match: :first

    assert_text "Availability schedule was successfully destroyed"
  end
end
