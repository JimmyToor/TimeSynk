require "test_helper"

class AvailabilityTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = users(:admin)
    availability = Availability.new(name: "Test Availability", user: user)
    assert availability.valid?
  end

  test "should require a name" do
    user = users(:admin)
    availability = Availability.new(name: "", user: user)
    refute availability.valid?
    assert_includes availability.errors[:name], "can't be blank"
  end

  test "should enforce maximum length for name and description" do
    user = users(:admin)
    long_text = "a" * 301
    availability = Availability.new(name: long_text, description: long_text, user: user)
    refute availability.valid?
    assert_includes availability.errors[:name], "is too long (maximum is 300 characters)"
    assert_includes availability.errors[:description], "is too long (maximum is 300 characters)"
  end

  test "should enforce uniqueness of name scoped to user" do
    existing_availability = availabilities(:user_admin_default_availability)
    user = existing_availability.user
    duplicate = Availability.new(name: existing_availability.name, user: user)
    refute duplicate.valid?
    assert_includes duplicate.errors[:name], I18n.t("activerecord.errors.models.availability.attributes.name.taken")
  end

  test "should return the user's username" do
    availability = availabilities(:user_admin_default_availability)
    assert_equal availability.user.username, availability.username
  end

  test "should not allow deletion if it's the only availability" do
    availability = availabilities(:user_groupsmemberuser_default_availability)
    assert_equal 1, availability.user.availabilities.count, "Fixture setup assumption failed: User should only have one availability for this test"

    assert_no_difference "Availability.count" do
      availability.destroy
    end
    assert_includes availability.errors[:base], I18n.t("availability.destroy.only_availability")
  end

  test "destroying availability cascades to proposal_availability" do
    user = users(:admin)
    proposal_availability_record = proposal_availabilities(:user_admin_group_1_game_thief_availability)
    proposal_availability_id = proposal_availability_record.id

    # Link the proposal availability
    availability_for_proposal = Availability.create!(name: "Temp Availability for Proposal", user: user)
    proposal_availability_record.update!(availability: availability_for_proposal)
    # Ensure the record is linked
    availability_for_proposal.reload

    assert ProposalAvailability.exists?(proposal_availability_id), "ProposalAvailability fixture record missing before destroy"
    assert_difference -> { Availability.count }, -1 do
      assert_difference -> { ProposalAvailability.count }, -1 do
        availability_for_proposal.destroy
      end
    end
    assert_raises(ActiveRecord::RecordNotFound) { ProposalAvailability.find(proposal_availability_id) }
  end

  test "destroying availability cascades to group_availability" do
    user = users(:admin)
    group_availability_record = group_availabilities(:user_admin_group_1_availability)
    group_availability_id = group_availability_record.id

    # Link the group availability
    availability_for_group = Availability.create!(name: "Temp Availability for Group", user: user)
    group_availability_record.update!(availability: availability_for_group)
    # Ensure the record is linked
    availability_for_group.reload

    assert GroupAvailability.exists?(group_availability_id), "GroupAvailability fixture record missing before destroy"
    assert_difference -> { Availability.count }, -1 do
      assert_difference -> { GroupAvailability.count }, -1 do
        availability_for_group.destroy
      end
    end
    assert_raises(ActiveRecord::RecordNotFound) { GroupAvailability.find(group_availability_id) }
  end

  test "destroying availability set as default re-assigns user_availability" do
    user = users(:admin)
    original_user_availability_record = user_availabilities(:user_admin_default)
    original_fallback_availability = original_user_availability_record.availability

    # Link user availability
    availability_for_user_default = Availability.create!(name: "Temp User Default", user: user)
    original_user_availability_record.update!(availability: availability_for_user_default)

    assert_difference -> { Availability.count }, -1 do
      availability_for_user_default.destroy
    end
    assert_equal original_fallback_availability.id, user.reload.user_availability.availability_id, "UserAvailability did not revert to original fallback"
  end
end
