require "application_system_test_case"

class UserAvailabilitiesTest < ApplicationSystemTestCase
  setup do
    @user_availability = user_availabilities(:one)
  end

  test "visiting the index" do
    visit user_availabilities_url
    assert_selector "h1", text: "User availabilities"
  end

  test "should create users availability" do
    visit user_availabilities_url
    click_on "New users availability"

    fill_in "Schedule", with: @user_availability.schedule_id
    fill_in "User", with: @user_availability.user_id
    click_on "Create User availability"

    assert_text "User availability was successfully created"
    click_on "Back"
  end

  test "should update User availability" do
    visit user_availability_url(@user_availability)
    click_on "Edit this users availability", match: :first

    fill_in "Schedule", with: @user_availability.schedule_id
    fill_in "User", with: @user_availability.user_id
    click_on "Update User availability"

    assert_text "User availability was successfully updated"
    click_on "Back"
  end

  test "should destroy User availability" do
    visit user_availability_url(@user_availability)
    click_on "Destroy this users availability", match: :first

    assert_text "User availability was successfully destroyed"
  end
end
