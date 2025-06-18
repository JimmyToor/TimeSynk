class PermissionSetPolicy < ApplicationPolicy
  attr_reader :most_permissive_role
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def initialize(user, record, most_permissive_role: nil)
    super(user, record)
    @most_permissive_role = most_permissive_role || user.most_permissive_cascading_role_for_resource(record.resource)
  end

  # Only concerned with the base permissions that allow editing roles for the resource,
  # and not with editing specific roles for specific users
  def edit?
    has_base_edit_permissions?
  end

  def update?(peer_user: nil, peer_user_most_permissive_role: nil)
    # only admins and owners for the resource (or the resource's role providing resources) can change roles for others,
    # and only for users with lower permissions
    # e.g. site_admin > group_owner > group_admin > game_proposal_owner > game_proposal_admin

    # Check if the user has the necessary permissions
    return false unless has_base_edit_permissions?

    # Only one user is being compared against
    if peer_user.present?
      peer_user_most_permissive_role ||= peer_user.most_permissive_cascading_role_for_resource(record.resource)
      return false if record.users_roles[peer_user.id].include?(most_permissive_role.id) # Cannot assign our highest role to another user
      return RoleHierarchy.supersedes?(most_permissive_role, peer_user_most_permissive_role)
    end

    record.users_roles.each do |peer_user_id, role_ids|
      return false if peer_user_id == user.id
      peer_most_permissive_role = User.find(peer_user_id).most_permissive_cascading_role_for_resource(record.resource)
      return false if role_ids.include?(most_permissive_role.id) # Cannot assign our highest role to another user
      return false unless RoleHierarchy.supersedes?(most_permissive_role, peer_most_permissive_role)
    end

    true
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  private

  def has_base_edit_permissions?
    if record.resource.class.const_defined?(:MIN_PERMISSION_EDIT_WEIGHT)
      RoleHierarchy.role_weight(most_permissive_role) <= record.resource.class::MIN_PERMISSION_EDIT_WEIGHT
    else
      false
    end
  end
end
