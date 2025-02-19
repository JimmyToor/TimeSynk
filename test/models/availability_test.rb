require "test_helper"

class AvailabilityTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "should be valid with valid attributes" do
    availability = Availability.new(name: "Test Availability", user: @user)
    assert availability.valid?
  end

  test "should require a name" do
    availability = Availability.new(name: "", user: @user)
    refute availability.valid?
    assert_includes availability.errors[:name], "can't be blank"
  end

  test "should enforce maximum length for name and description" do
    long_text = "a" * 301
    availability = Availability.new(name: long_text, description: long_text, user: @user)
    refute availability.valid?
    assert_includes availability.errors[:name], "is too long (maximum is 300 characters)"
    assert_includes availability.errors[:description], "is too long (maximum is 300 characters)"
  end

  test "should enforce uniqueness of name scoped to user" do
    Availability.create!(name: "Unique", user: @user)
    duplicate = Availability.new(name: "Unique", user: @user)
    refute duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should return the user's username" do
    availability = Availability.create!(name: "Return Username", user: @user)
    assert_equal @user.username, availability.username
  end

  test "should not allow deletion if it's the only availability" do
    availability = @user.availabilities.first
    assert_no_difference "Availability.count" do
      # Only availability should be the default created from user creation.
      availability.destroy
    end
    assert_includes availability.errors[:base], "Cannot delete your only availability"
  end

  test "should handle associations on destroy" do
    availability1 = Availability.create!(name: "Primary Availability", user: @user)
    availability2 = Availability.create!(name: "Secondary Availability", user: @user)
    availability3 = Availability.create!(name: "Tertiary Availability", user: @user)
    fallback_availability = @user.availabilities.where.not(id: @user.user_availability.availability.id).first

    group = GroupCreationService.new({name: "Test Group"}, @user).create_group_and_membership
    game_proposal = GameProposal.create!(game_id: 1, group: group)

    @user.user_availability.update!(user: @user, availability: availability1)
    group_availability = GroupAvailability.create!(user: @user, availability: availability2, group: group)
    proposal_availability = ProposalAvailability.create!(user: @user, availability: availability3, game_proposal: game_proposal)

    assert_difference "Availability.count", -1 do
      availability3.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { ProposalAvailability.find(proposal_availability.id) }

    assert_difference "Availability.count", -1 do
      availability2.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { ProposalAvailability.find(group_availability.id) }

    assert_difference "Availability.count", -1 do
      availability1.destroy
    end
    assert_equal fallback_availability.id, @user.user_availability.availability_id
  end
end
