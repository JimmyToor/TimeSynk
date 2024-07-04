require "application_system_test_case"

class InvitesTest < ApplicationSystemTestCase
  setup do
    @invite = invites(:one)
  end

  test "visiting the index" do
    visit group_invites_url
    assert_selector "h1", text: "Group invites"
  end

  test "should create group invite" do
    visit group_invites_url
    click_on "New group invite"

    fill_in "Expires at", with: @invite.expires_at
    fill_in "Group", with: @invite.group_id
    fill_in "Invite token", with: @invite.invite_token
    fill_in "Roles", with: @invite.role_ids
    fill_in "User", with: @invite.user_id
    click_on "Create Group invite"

    assert_text "Group invite was successfully created"
    click_on "Back"
  end

  test "should update Group invite" do
    visit invite_url(@invite)
    click_on "Edit this group invite", match: :first

    fill_in "Expires at", with: @invite.expires_at
    fill_in "Group", with: @invite.group_id
    fill_in "Invite token", with: @invite.invite_token
    fill_in "Roles", with: @invite.role_ids
    fill_in "User", with: @invite.user_id
    click_on "Update Group invite"

    assert_text "Group invite was successfully updated"
    click_on "Back"
  end

  test "should destroy Group invite" do
    visit invite_url(@invite)
    click_on "Destroy this group invite", match: :first

    assert_text "Group invite was successfully destroyed"
  end
end
