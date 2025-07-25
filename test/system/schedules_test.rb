require "application_system_test_case"

class SchedulesTest < ApplicationSystemTestCase
  setup do
    @schedule = schedules(:user_admin_default)
  end

  test "visiting the index" do
    visit schedules_url
    assert_selector "h1", text: "Schedules"
  end

  test "should create schedule" do
    visit schedules_url
    click_on "New schedule"

    fill_in "Duration", with: @schedule.duration
    fill_in "End date", with: @schedule.end_time
    fill_in "Schedule pattern", with: @schedule.schedule_pattern
    fill_in "Start date", with: @schedule.start_time
    click_on "Create Schedule"

    assert_text "Schedule was successfully created"
    click_on "Back"
  end

  test "should update Schedule" do
    visit schedule_url(@schedule)
    click_on "Edit this schedule", match: :first

    fill_in "Duration", with: @schedule.duration
    fill_in "End date", with: @schedule.end_time
    fill_in "Schedule pattern", with: @schedule.schedule_pattern
    fill_in "Start date", with: @schedule.start_time
    click_on "Update Schedule"

    assert_text "Schedule was successfully updated"
    click_on "Back"
  end

  test "should destroy Schedule" do
    visit schedule_url(@schedule)
    click_on "Destroy this schedule", match: :first

    assert_text "Schedule was successfully destroyed"
  end
end
