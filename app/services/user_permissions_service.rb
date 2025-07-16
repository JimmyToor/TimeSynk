# frozen_string_literal: true

# Provides methods to retrieve role-related information for a user
class UserPermissionsService
  def initialize(user)
    @user = user
  end

  # @return [ActiveRecord::Relation] The roles of the user for the resource.
  def roles_for_resource(resource)
    @user.roles.where(resource: resource)
  end

  # Checks if the user's roles supersede the roles of another user for a specific resource.
  #
  # @param peer_user [User] The user whose roles are being compared against.
  # @param resource [ActiveRecord::Base] The resource for which the roles are being compared.
  # @return [Boolean] True if the user's roles supersede the other user's roles for the resource, false otherwise.
  def supersedes_user_in_resource?(peer_user, resource)
    other_user_most_permissive_role = peer_user.most_permissive_cascading_role_for_resource(resource)
    our_most_permissive_role = most_permissive_cascading_role_for_resource(resource)
    RoleHierarchy.supersedes?(our_most_permissive_role, other_user_most_permissive_role)
  end

  # @return [Role] the highest role a user has for a particular resource.
  def most_permissive_role_for_resource(resource)
    @user.roles.where(resource: resource).min_by { |role| RoleHierarchy.role_weight(role) }
  end

  # @return [Integer] The weight of the most permissive role a user has for a particular resource.
  def most_permissive_role_weight_for_resource(resource)
    @user.roles.where(resource: resource).map { |role| RoleHierarchy.role_weight(role) }.min || RoleHierarchy::NON_PERMISSIVE_WEIGHT
  end

  # @return [Role] The highest role a user has for a particular resource, including roles from parent resources.
  def most_permissive_cascading_role_for_resource(resource)
    current_highest_role = most_permissive_role_for_resource(resource)

    return current_highest_role unless resource.class.respond_to?(:role_providing_associations)

    resource.class.role_providing_associations.each do |association_name|
      parent_resource = resource.send(association_name)
      next if parent_resource.nil?

      parent_highest_role = most_permissive_cascading_role_for_resource(parent_resource)

      if RoleHierarchy.supersedes?(parent_highest_role, current_highest_role)
        current_highest_role = parent_highest_role
      end
    end
    current_highest_role
  end

  # Checks if the current user has the base permissions to update the user's roles for the resource,
  # irrespective of specific roles that can be changed.
  # @param peer_user [User] The user whose roles are being updated.
  # @param resource [ActiveRecord::Base] The resource for which permissions are being updated.
  # @param most_permissive_role [Role, nil] The most permissive role of the assigning user for the resource.
  # @param peer_user_most_permissive_role [Role, nil] The most permissive role of the peer user for the resource.
  # @return [Boolean] True if the user can update roles for the resource, false otherwise.
  def can_update_resource_permissions_for_peer_user?(peer_user, resource, most_permissive_role: nil, peer_user_most_permissive_role: nil)
    most_permissive_role ||= @user.most_permissive_cascading_role_for_resource(resource)
    peer_user_most_permissive_role ||= peer_user.most_permissive_cascading_role_for_resource(resource)

    policy = PermissionSetPolicy.new(@user, resource.make_permission_set([@user, peer_user]), most_permissive_role)
    policy.update_single_peer?(peer_user, peer_user_most_permissive_role)
  end

  # Checks if the user has any of the specified roles for a given resource.
  # @param roles_to_check [Array<String>] The role names to check for.
  # @param resource [ActiveRecord::Base] The resource to check against.
  # @return [Boolean] True if the user has any of the specified roles for the resource, false otherwise.
  def has_any_role_for_resource?(roles_to_check, resource)
    roles_to_check.any? { |role| @user.has_cached_role?(role, resource) }
  end

  # Retrieves the roles the user can assign to the affected user for a specific resource.
  #
  # @param peer_user [User] The user whose available roles are being checked.
  # @param resource [ActiveRecord::Base] The resource for which the roles are being checked.
  # @param most_permissive_role [Role, nil] The most permissive role of the enacting user for the resource.
  # @return [Array<Role>] An array of roles that the affected user can be assigned to for the resource.
  def assignable_roles_for_resource(peer_user, resource, most_permissive_role = nil)
    return [] unless peer_user && resource

    most_permissive_role ||= Current.user.most_permissive_role_for_resource(resource)

    existing_role_ids = peer_user.roles_for_resource(resource).non_special.pluck(:id)
    existing_role_ids << most_permissive_role.id if most_permissive_role

    resource.roles.where.not(id: existing_role_ids)
  end
end
