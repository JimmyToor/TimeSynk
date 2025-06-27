require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user creation creates initial user availability" do
    user = User.new(email: "test@example.com", username: "testuser", password: "password")
    user.save!
    assert_not_nil user.user_availability
  end

  test "creation without username fails validation" do
    user = User.new(email: "no_username@example.com", password: "password")
    assert_raises(ActiveRecord::RecordInvalid) do
      user.save!
    end
  end

  test "creation without email still creates initial user availability" do
    user = User.new(username: "noemailuser", password: "password")
    user.save!
    assert_not_nil user.user_availability
  end

  test "cannot update password to a short value" do
    user = User.create!(email: "short_pw@example.com", username: "short_pw", password: "initialpass")
    assert_raises(ActiveRecord::RecordInvalid) do
      user.update!(password: "short")
    end
  end

  test "preserves only current session when updating password" do
    user = User.create!(email: "keep_session@example.com", username: "keep_session", password: "initialpass")
    user.sessions.create!
    user.sessions.create!
    current_session = user.sessions.create!
    Current.session = current_session
    user.update!(password: "newpassword")
    assert_equal 0, user.sessions.where.not(id: current_session.id).count
    assert user.sessions.exists?(id: current_session.id)
  end

  test "updates password with same length value" do
    user = User.create!(email: "same_len@example.com", username: "same_len", password: "password1")
    user.update!(password: "password2")
    assert user.authenticate("password2")
  end

  test "updates password with longer value" do
    user = User.create!(email: "longer_pw@example.com", username: "longer_pw", password: "password1")
    user.update!(password: "longerpassword123")
    assert user.authenticate("longerpassword123")
  end

  test "updating non-password attributes preserves sessions" do
    user = User.create!(email: "preserve@example.com", username: "preserve", password: "password123")
    session = user.sessions.create!
    user.update!(username: "new_username")
    assert user.sessions.exists?(id: session.id)
  end

  test "updating email to a different value sets verified to false" do
    user = User.create!(email: "oldmail@example.com", username: "newemail", password: "password123")
    user.update!(verified: true)
    assert user.verified
    user.update!(email: "newmail@example.com")
    assert_not user.verified
  end

  test "should not update email if email is already verified by another user" do
    user = users(:radperson)
    user.update! verified: false

    assert_raises(ActiveRecord::RecordInvalid) do
      user.update!(email: users(:admin).email)
    end
  end

  test "should clear identical email from other users on verification" do
    user = users(:radperson)
    other_user = users(:groupsmemberuser)

    user.update!(email: "newemail@test.com", verified: false)
    other_user.update!(email: "newemail@test.com", verified: false)

    assert_equal user.email, other_user.email

    other_user.update! verified: true
    user.reload

    assert_not_equal user.email, other_user.email
  end

  test "membership_for_group returns correct membership" do
    user = users(:cooluserguy)
    group = groups(:two_members)
    membership = user.get_membership_for_group(group)
    assert_equal group, membership.group
    assert_equal user, membership.user
  end

  test "get_vote_for_proposal returns user's vote" do
    user = users(:cooluserguy)
    vote = proposal_votes(:proposal_2_user_2_yes)
    proposal = vote.game_proposal
    assert_equal vote, user.get_vote_for_proposal(proposal)
  end

  test "nearest_proposal_availability follows fallback hierarchy" do
    user = users(:admin)
    proposal = game_proposals(:group_1_game_1)

    # Test proposal availability
    assert_equal proposal_availabilities(:user_1_proposal_1_availability).availability, user.nearest_proposal_availability(proposal)

    # Test fallback to group availability
    proposal.proposal_availabilities.destroy_all
    assert_equal group_availabilities(:user_1_group_1_availability).availability, user.nearest_proposal_availability(proposal)

    # Test fallback to user availability
    group = groups(:one_member)
    group.group_availabilities.destroy_all
    assert_equal user.user_availability.availability, user.nearest_proposal_availability(proposal)
  end

  test "roles_for_resource returns roles for given game proposal" do
    user = users(:cooluserguy)
    proposal = game_proposals(:group_2_game_2)
    role1 = roles(:game_proposal_2_owner) # user already has this role
    role2 = roles(:game_proposal_2_admin)
    user.roles << role2
    assert_equal [role1, role2], user.roles_for_resource(proposal).to_a
  end

  test "roles_for_resource returns roles for given game session" do
    user = users(:admin)
    game_session = game_sessions(:proposal_1_session_1)
    role = roles(:game_session_1_owner)
    assert_includes user.roles_for_resource(game_session), role
  end

  test "supersedes_user_in_resource returns true if user supersedes role user" do
    user = users(:admin)
    role_user = users(:cooluserguy)
    game_proposal = game_proposals(:group_1_game_1)
    assert user.supersedes_user_in_resource?(role_user, game_proposal)
  end

  test "most_permissive_role_for_resource returns highest role for game proposal" do
    user = users(:admin)
    game_proposal = game_proposals(:group_1_game_1)
    role = roles(:admin_1)
    user.roles << role
    expected = roles(:game_proposal_1_owner)
    assert_equal expected, user.most_permissive_role_for_resource(game_proposal)
  end

  test "most_permissive_cascading_role_for_resource returns superseding group role" do
    user = users(:radperson)
    game_proposal = game_proposals(:group_3_game_1)
    role = roles(:game_proposal_2_admin)
    expected = roles(:admin_3)
    user.roles << role
    assert_equal expected, user.most_permissive_cascading_role_for_resource(game_proposal)
  end

  test "supersedes_user_in_resource returns true if user supersedes role user in group" do
    user = users(:cooluserguy) # already has owner role
    role_user = users(:radperson)
    group = groups(:two_members)
    role_user.roles << roles(:admin_2)
    assert user.supersedes_user_in_resource?(role_user, group)
  end

  test "supersedes_user_in_resource returns false if user does not supersede role user in group" do
    user = users(:radperson)
    role_user = users(:cooluserguy) # already has owner role
    group = groups(:two_members)
    assert_not user.supersedes_user_in_resource?(role_user, group)
  end

  test "most_permissive_role_for_resource returns most permissive role for resource" do
    user = users(:cooluserguy) # already has owner role
    resource = game_proposals(:group_2_game_2)
    user.roles << roles(:admin_1)
    expected = roles(:game_proposal_2_owner)
    assert_equal expected, user.most_permissive_role_for_resource(resource)
  end

  test "most_permissive_role_weight_for_resource returns most permissive role weight for resource" do
    user = users(:admin)
    resource = game_proposals(:group_1_game_1)
    expected = RoleHierarchy.role_weight(roles(:game_proposal_1_owner))
    role = roles(:admin_1)
    user.roles << role
    assert_equal expected, user.most_permissive_role_weight_for_resource(resource)
  end

  test "update_roles adds and removes roles correctly" do
    user = users(:admin)
    role_to_add = roles(:site_admin)
    role_to_remove = roles(:admin_1)
    existing_roles = user.roles.to_a

    user.roles << role_to_remove
    user.update_roles(add_roles: [role_to_add.id], remove_roles: [role_to_remove.id])

    roles = user.roles.to_a

    assert_includes roles, role_to_add
    assert_not_includes roles, role_to_remove

    existing_roles.each do |role|
      assert_includes roles, role
    end
  end
end
