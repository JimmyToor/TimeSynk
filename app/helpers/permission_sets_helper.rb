module PermissionSetsHelper
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
end
