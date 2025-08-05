require "application_system_test_case"

class GroupsTest < ApplicationSystemTestCase
  test "visiting the index" do
    groups(:three_members)
    user = users(:radperson)
    sign_in_as user

    click_on I18n.t("nav.groups")
    assert_selector "h1", text: "Groups"
  end

  test "should create group" do
    user = users(:radperson)
    sign_in_as user

    new_group_name = "newgroup"

    visit groups_url
    click_on I18n.t("group.new.button_text")

    fill_in "Name", with: new_group_name
    click_on "Create Group"

    assert_text I18n.t("group.create.success", group_name: new_group_name)
  end

  test "should visit group" do
    group = groups(:three_members)
    user = users(:radperson)
    sign_in_as user

    visit groups_url
    click_on "Go to #{group.name}"

    assert_text group.name
    assert_text I18n.t("group_membership.destroy.self.button_text")
  end

  test "should update Group" do
    group = groups(:two_members)
    user = users(:cooluserguy)
    sign_in_as user

    visit group_url(group)
    click_on I18n.t("group.edit.button_title")

    new_group_name = "#{group.name} - updated"
    fill_in "group_name", with: new_group_name
    click_on "Update Group"

    assert_text I18n.t("group.update.success", group_name: new_group_name)
  end

  test "should not have edit button if not group owner" do
    group = groups(:three_members)
    user = users(:radperson)
    sign_in_as user

    visit group_url(group)

    assert_no_text I18n.t("group.edit.button_title")
  end

  test "should destroy Group" do
    group = groups(:two_members)
    user = users(:cooluserguy)
    sign_in_as user

    visit group_url(group)
    find("#group_#{group.id}_misc_dropdown_button").click

    click_on I18n.t("group.destroy.button_text")

    fill_in I18n.t("group.destroy.confirm_name"), with: group.name
    check I18n.t("group.destroy.confirm")
    click_on "Delete"

    assert_text I18n.t("group.destroy.success", group_name: group.name)
  end

  test "should transfer group ownership" do
    group = groups(:two_members)
    user = users(:cooluserguy)
    sign_in_as user

    visit group_url(group)
    find("#group_#{group.id}_misc_dropdown_button").click
    click_on I18n.t("ownership.transfer")

    check I18n.t("ownership.edit.confirm", resource_type: "Group")
    click_on I18n.t("ownership.edit.submit_text")

    assert_text I18n.t("ownership.update.success", new_owner: users(:radperson).username)
  end
end
