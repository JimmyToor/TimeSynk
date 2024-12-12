module GroupMembershipsHelper
  def can_kick_user?(group_membership)
    group_membership.user != Current.user && policy(group_membership).destroy? && !group_membership.user.has_role?(:owner, group_membership.group)
  end
end
