require "application_system_test_case"

class InvitesTest < ApplicationSystemTestCase
  setup do
    @user = users(:groupsmemberuser)
    sign_in_as @user
  end

  test "visiting the index via button" do
    group = groups(:three_members)

    visit group_url(group)

    find("#group_#{group.id}_misc_dropdown_button").click

    click_on I18n.t("invite.index.button_text")

    assert_selector "h2", text: I18n.t("invite.index.title", group_name: group.name)
  end

  test "should create group invite with defaults" do
    group = groups(:three_members_0_proposals)

    visit group_invites_url(group)
    click_on I18n.t("invite.new.button_text")

    click_on "Save"

    assert_text I18n.t("invite.create.success")
    click_on "Back"
  end

  test "should update group invite" do
    group = groups(:three_members_0_proposals)

    visit group_invites_url(group)

    button_title = I18n.t("invite.edit.button_title")
    find("a[title='#{button_title}']").click

    check I18n.t("group.role.kick_users")
    click_on "Save"

    assert_text I18n.t("invite.update.success")
  end

  test "should destroy group invite" do
    group = groups(:three_members_0_proposals)

    visit group_invites_url(group)
    button_title = I18n.t("invite.destroy.button_title")

    accept_confirm do
      find("a[title='#{button_title}']").click
    end

    assert_text I18n.t("invite.destroy.success")
  end
end
