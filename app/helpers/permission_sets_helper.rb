module PermissionSetsHelper
  def can_update_resource_permissions_for_user?(user, resource)
    permission_policy_class_for_resource(resource).new(Current.user, PermissionSet.new(resource: resource, users_roles: {user.id => nil})).update?
  end

  def permission_policy_class_for_resource(resource)
    policy_class_name = "#{resource.class}PermissionSetPolicy"
    policy_class = policy_class_name.safe_constantize
    raise NameError, "Uninitialized constant #{policy_class_name}. Could not find the permission set policy for #{resource.class.name}." unless policy_class

    policy_class
  end

  def group_permission_set_policy(group_permission_set)
    GroupPermissionSetPolicy.new(Current.user, group_permission_set)
  end

  def game_proposal_permission_set_policy(game_proposal_permission_set)
    GameProposalPermissionSetPolicy.new(Current.user, game_proposal_permission_set)
  end
end
