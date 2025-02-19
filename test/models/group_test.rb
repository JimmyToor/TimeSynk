require "test_helper"

class GroupTest < ActiveSupport::TestCase
  setup do
    @group = Group.create(name: "Test Group")
  end

  test "get_user_group_availability returns correct availability" do
    user = users(:two)
    availability = group_availabilities(:user_2_group_2_availability)
    @group.group_availabilities << availability
    assert_equal availability, @group.get_user_group_availability(user)
  end

  test "get_user_group_availability returns nil if no availability" do
    user = users(:two)
    assert_nil @group.get_user_group_availability(user)
  end

  test "is_user_member? returns true if user is a member" do
    user = users(:two)
    @group.users << user
    assert @group.is_user_member?(user)
  end

  test "is_user_member? returns false if user is not a member" do
    user = users(:two)
    assert_not @group.is_user_member?(user)
  end

  test "membership_for_user returns correct membership" do
    user = users(:two)
    membership = GroupMembership.new(user: user, group: @group)
    assert_nil @group.membership_for_user(user)
    @group.group_memberships << membership
    assert_equal @group.membership_for_user(user), membership
  end

  test "membership_for_user returns nil if no membership" do
    user = users(:two)
    assert_nil @group.membership_for_user(user)
  end
end
