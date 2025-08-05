require "application_system_test_case"

class SchedulesTest < ApplicationSystemTestCase
  setup do
    @user = users(:radperson)
    sign_in_as @user
  end

  test "visiting the index" do
    visit schedules_url
    assert_selector "h1", text: "Schedules"

    assert_selector "#schedule_table" do
      assert_selector "tbody tr", count: @user.schedules.count * 2
    end
  end

  test "should create schedule" do
    visit schedules_url
    click_on I18n.t("schedule.new.title")

    fill_in "Name", with: "New Test Schedule"
    click_on I18n.t("schedule.edit.submit_text")

    assert_text I18n.t("schedule.create.success")
  end

  test "should create schedule and add to availability" do
    availability = availabilities(:user_radperson_default_availability)
    visit schedules_url
    click_on I18n.t("schedule.new.title")

    new_name = "New Test Schedule with Availability"
    fill_in "Name", with: new_name
    click_on I18n.t("schedule.add_availability")
    select availability.name
    click_on I18n.t("schedule.edit.submit_text")

    assert_text I18n.t("schedule.create.success")

    visit availability_url(availability)
    assert_text new_name
  end

  test "should update Schedule with pattern" do
    schedule = schedules(:user_radperson_unique_name)
    visit schedule_url(schedule)
    click_on I18n.t("generic.edit_resource", resource_type: "Schedule")

    fill_in "Hours", with: 2
    select "Custom", from: "schedule_schedule_pattern"
    click_on I18n.t("schedule.edit.submit_text")

    assert_text I18n.t("schedule.update.success")
  end

  test "should destroy Schedule" do
    schedule = schedules(:user_radperson_unique_name)
    visit schedule_url(schedule)

    click_on I18n.t("generic.delete")

    check I18n.t("schedule.destroy.confirm")

    click_on I18n.t("generic.delete")

    assert_text I18n.t("schedule.destroy.success")
  end

  test "should not create Schedule with existing name" do
    visit schedules_url
    click_on I18n.t("schedule.new.title")

    fill_in "Name", with: schedules(:user_radperson_unique_name).name
    click_on I18n.t("schedule.edit.submit_text")

    assert_text I18n.t("schedule.create.error")
  end

  test "should not show unauthorized Schedule" do
    unauthorized_schedule = schedules(:user_admin_default)
    visit schedule_url(unauthorized_schedule)

    assert_text I18n.t("pundit.not_authorized")
  end
end
