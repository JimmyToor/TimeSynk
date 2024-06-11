require "application_system_test_case"

class GroupAvailabilitiesTest < ApplicationSystemTestCase
  setup do
    @group_availability = group_availabilities(:one)
  end

  test "visiting the index" do
    visit group_availabilities_url
    assert_selector "h1", text: "Group availabilities"
  end

  test "should create group availability" do
    visit group_availabilities_url
    click_on "New group availability"

    fill_in "Group", with: @group_availability.group_id
    fill_in "Schedule", with: @group_availability.schedule_id
    fill_in "User", with: @group_availability.user_id
    click_on "Create Group availability"

    assert_text "Group availability was successfully created"
    click_on "Back"
  end

  test "should update Group availability" do
    visit group_availability_url(@group_availability)
    click_on "Edit this group availability", match: :first

    fill_in "Group", with: @group_availability.group_id
    fill_in "Schedule", with: @group_availability.schedule_id
    fill_in "User", with: @group_availability.user_id
    click_on "Update Group availability"

    assert_text "Group availability was successfully updated"
    click_on "Back"
  end

  test "should destroy Group availability" do
    visit group_availability_url(@group_availability)
    click_on "Destroy this group availability", match: :first

    assert_text "Group availability was successfully destroyed"
  end
end
