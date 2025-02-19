class GroupPermissionSetPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def edit?
    user.most_permissive_role_weight_for_resource(record.resource) <= RoleHierarchy::ROLE_WEIGHTS[:"group.admin"]
  end

  def update?
    # only admins and owners for the group can change roles for others, and only for users with lower permissions
    # site_admin > group_owner > group_admin > others

    # Check if the user has the necessary permissions
    role_weight = user.most_permissive_role_weight_for_resource(record.resource)
    return true if role_weight <= RoleHierarchy::ROLE_WEIGHTS[:"group.owner"]
    return false unless role_weight <= RoleHierarchy::ROLE_WEIGHTS[:"group.admin"]

    # Check if the user is trying to change the roles of a user with higher permissions, or themselves
    record.users_roles&.each do |user_id, _|
      role_user_role_weight = User.find(user_id).most_permissive_role_weight_for_resource(record.resource)
      return false if user_id == user.id || role_user_role_weight <= RoleHierarchy::ROLE_WEIGHTS[:"group.admin"]
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

  def role_user_is_owner_or_admin?(role_user)
    role_user.most_permissive_role_weight_for_resource(record.resource) <= RoleHierarchy::ROLE_WEIGHTS[:"group.admin"]
  end

  def is_site_admin_or_group_owner?
    user.has_cached_role?(:site_admin) || user.has_cached_role?(:owner, record.resource)
  end
end
