require "test_helper"

class GroupMembershipTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "should create group membership" do
    group = groups(:two_members)
    assert_difference("GroupMembership.count") do
      GroupMembership.create(group: group, user: @user)
    end
  end
end
