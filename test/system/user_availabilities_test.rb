require "application_system_test_case"

class UserAvailabilitiesTest < ApplicationSystemTestCase
  test "should update default Availability" do
    user = users(:cooluserguy)
    sign_in_as user

    availability = availabilities(:user_cooluserguy_empty_availability)
    visit availabilities_url

    click_on I18n.t("user_availability.edit.button_text"), match: :first
    select availability.name

    click_on I18n.t("user_availability.edit.submit_text")
  end
end
