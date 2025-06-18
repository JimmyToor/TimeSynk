module PermissionSetsHelper
  def permission_policy_class_for_resource(resource)
    policy_class_name = "#{resource.class}PermissionSetPolicy"
    policy_class = policy_class_name.safe_constantize
    raise NameError, "Uninitialized constant #{policy_class_name}. Could not find the permission set policy for #{resource.class.name}." unless policy_class

    policy_class
  end

  # Checks if the current user has the base permissions to update the user's roles for the resource,
  # irrespective of specific roles that can be changed.
  def can_update_resource_permissions_for_peer_user?(peer_user, resource, most_permissive_role: nil, peer_user_most_permissive_role: nil)
    most_permissive_role ||= Current.user.most_permissive_cascading_role_for_resource(resource)
    peer_user_most_permissive_role ||= peer_user.most_permissive_cascading_role_for_resource(resource)

    policy = PermissionSetPolicy.new(peer_user, peer_user.make_permission_set_for_resource(resource), most_permissive_role: most_permissive_role)
    policy.update?(peer_user: peer_user, peer_user_most_permissive_role: peer_user_most_permissive_role)
  end

  def group_permission_set_policy(group_permission_set)
    GroupPermissionSetPolicy.new(Current.user, group_permission_set)
  end

  def game_proposal_permission_set_policy(game_proposal_permission_set)
    GameProposalPermissionSetPolicy.new(Current.user, game_proposal_permission_set)
  end

  # Derives a unique ID for the permission set frame based on the user and the resource type.
  # @param user [User] The user for whom the permission set is being derived.
  # @param group [Group, nil] The group associated with the permission set.
  # @param game_proposal [GameProposal, nil] The game proposal associated with the permission set.
  # @param game_session [GameSession, nil] The game session associated with the permission set.
  # @param prepend [String, nil] An optional string to prepend to the ID.
  # @note Only one of `group`, `game_proposal`, or `game_session` should be provided.
  def derive_permission_set_frame_id(user: nil, group: nil, game_proposal: nil, game_session: nil)
    if game_session
      "permission_set_user_#{user.id}_game_session_#{game_session.id}"
    elsif game_proposal
      "permission_set_user_#{user.id}_game_proposal_#{game_proposal.id}"
    elsif group
      "permission_set_user_#{user.id}_group_#{group.id}"
    else
      raise ArgumentError, "No valid resource provided"
    end
  end

  def permission_set_path_for_resource(user, resource)
    resource_type = resource.model_name.param_key
    path_helper_name = "#{resource_type}_permission_set_path"

    if respond_to?(path_helper_name)
      send(path_helper_name, user_id: user.id, "#{resource_type}_id": resource.id)
    else
      raise ArgumentError, "permission_sets_helper#permission_set_path_for_resource:Unsupported resource type: #{resource_type}. No path helper found: #{path_helper_name}"
    end
  end

  def assignable_roles_for_resource(user, resource, most_permissive_role = nil)
    return {} unless user && resource
    most_permissive_role ||= user.most_permissive_role_for_resource(resource)
    (resource.roles - user.roles_for_resource(resource) - [most_permissive_role]).reject { |role| RoleHierarchy.special?(role) }
  end
end
