require "application_system_test_case"

class AvailabilitiesTest < ApplicationSystemTestCase
  setup do
  end

  test "visiting the index" do
    user = users(:radperson)
    sign_in_as user

    visit availabilities_url
    assert_selector "h1", text: I18n.t("availability.title")

    assert_selector "#availability_table" do
      assert_selector "tbody tr", count: [user.availabilities.count * 2, Pagy::DEFAULT[:limit]].min
    end
  end

  test "should create availability" do
    user = users(:radperson)
    sign_in_as user

    visit availabilities_url
    click_on I18n.t("availability.new.button_text")

    new_name = "New Test Availability"
    fill_in I18n.t("availability.name.field_label"), with: new_name
    fill_in I18n.t("availability.description.field_label"), with: "This is a test availability description."

    schedule = schedules(:user_radperson_unique_name)
    find("input[data-schedule-id='#{schedule.id}']").set(true)

    click_on I18n.t("availability.edit.submit_text")
    assert_text new_name
    assert_text I18n.t("availability.create.success")
  end

  test "should update Availability" do
    user = users(:radperson)
    sign_in_as user

    availability = availabilities(:user_radperson_default_availability)
    visit availability_url(availability)

    click_on I18n.t("generic.edit_resource", resource_type: "Availability"), match: :first

    schedule = schedules(:user_radperson_unique_name)
    fill_in I18n.t("availability.name.field_label"), with: "New Test Availability Name"
    find("input[data-schedule-id='#{schedule.id}']").set(false)

    click_on I18n.t("availability.edit.submit_text")
    assert_text "None"
    assert_text I18n.t("availability.update.success")
  end

  test "should destroy Availability" do
    user = users(:cooluserguy)
    sign_in_as user

    availability = availabilities(:user_cooluserguy_empty_availability)
    visit availability_url(availability)

    click_on I18n.t("generic.delete_resource", resource_type: "Availability"), match: :first
    check I18n.t("availability.destroy.confirm")
    click_on I18n.t("generic.delete")

    assert_text I18n.t("availability.destroyed")
  end

  test "should not destroy only Availability" do
    user = users(:radperson)
    sign_in_as user

    availability = availabilities(:user_radperson_default_availability)
    visit availability_url(availability)

    click_on I18n.t("generic.delete_resource", resource_type: "Availability"), match: :first
    check I18n.t("availability.destroy.confirm")
    click_on I18n.t("generic.delete")

    assert_text I18n.t("availability.destroy.error")
  end
end
