require "application_system_test_case"

class GroupMembershipsTest < ApplicationSystemTestCase
  include RolesHelper

  test "should view membership list" do
    user = users(:radperson)
    group = groups(:three_members)
    sign_in_as(user)
    visit group_url(group)

    click_on I18n.t("group_membership.index.button_title"), match: :first

    assert_selector "tbody tr th", count: group.group_memberships.count
  end

  test "should view group membership details" do
    user = users(:radperson)
    group = groups(:three_members)
    sign_in_as(user)

    visit group_url(group)

    label = I18n.t("group.view_roles_label", username: user.username, group_name: group.name)

    find("button[aria-label='#{label}']").click

    assert_text I18n.t("group_membership.created_at.field_label")
    assert_text I18n.t("permission_set.roles.title", resource_type: group.class.name.titleize)

    roles = user.roles.where(resource: group)
    roles.each do |role|
      assert_text format_group_role(role)
    end
  end

  test "should join group" do
    user = users(:groupsmemberuser)
    invite = invites(:group_twomembers_role_manage_users)
    sign_in_as(user)

    visit groups_url
    click_on I18n.t("group.join.button_text")

    fill_in I18n.t("invite.token.field_label"), with: invite.invite_token
    click_on I18n.t("group.join.button_text")

    click_on I18n.t("invite.accept_invite")

    assert_text I18n.t("group_membership.create.success", group_name: invite.group.name)
  end

  test "should leave group" do
    user = users(:radperson)
    group = groups(:three_members)
    sign_in_as(user)

    visit group_url(group)

    accept_confirm do
      click_on I18n.t("group_membership.destroy.self.button_text")
    end

    assert_text I18n.t("group_membership.destroy.self.success", group_name: group.name)
  end

  test "should kick user from group" do
    user = users(:cooluserguy)
    user_to_kick = users(:radperson)
    group = groups(:three_members)
    sign_in_as(user)

    visit group_url(group)

    click_on I18n.t("group_membership.index.button_title"), match: :first

    accept_confirm do
      find_link(I18n.t("group_membership.destroy.button_title", username: user_to_kick.username)).click
    end

    assert_text I18n.t("group_membership.destroy.success", username: user_to_kick.username, group_name: group.name)
  end
end
