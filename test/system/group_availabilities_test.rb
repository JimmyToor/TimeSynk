require "application_system_test_case"

class GroupAvailabilitiesTest < ApplicationSystemTestCase
  setup do
    @user = sign_in_as(users(:cooluserguy))
  end

  test "should update Group Availability" do
    group = groups(:two_members)

    visit group_url(group)
    click_on "group_#{group.id}_misc_dropdown_button"
    click_on I18n.t("group_availability.edit.button_text")

    availability = availabilities(:user_cooluserguy_empty_availability)
    select availability.name
    click_on I18n.t("group_availability.edit.submit_text")

    assert_text I18n.t("group_availability.update.success", availability_name: availability.name)
  end

  test "should create Group Availability" do
    group = groups(:three_members)

    visit group_url(group)
    click_on "group_#{group.id}_misc_dropdown_button"
    click_on I18n.t("group_availability.new.button_text")

    availability = availabilities(:user_cooluserguy_empty_availability)
    select availability.name
    click_on I18n.t("group_availability.edit.submit_text")

    assert_text I18n.t("group_availability.create.success", availability_name: availability.name)
  end

  test "should destroy Group Availability" do
    availabilities(:user_cooluserguy_empty_availability)

    group = groups(:two_members)
    visit group_url(group)

    click_on "group_#{group.id}_misc_dropdown_button"
    click_on I18n.t("group_availability.edit.button_text")

    accept_confirm do
      click_on I18n.t("group_availability.destroy.submit_text")
    end

    assert_text I18n.t("group_availability.destroy.success", group_name: group.name)
  end
end
