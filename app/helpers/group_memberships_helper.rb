module GroupMembershipsHelper
  # Determines if the current user can kick another user from a group.
  # @return [Boolean] true if the user can kick, false otherwise.
  # @param group_membership [GroupMembership] the membership of the user to check.
  # @note This provides an additional check over the policy to ensure that the user cannot kick themselves.
  def can_kick_user?(group_membership)
    group_membership.user != Current.user && policy(group_membership).destroy?
  end
end
