class InvitePolicy < ApplicationPolicy
  def new?
    user.has_any_role_for_resource?([:owner, :admin, :manage_invites], record.group)
  end

  def show?
    return false unless record.group.is_user_member?(user)
    return true if record.assigned_roles.empty?

    user_role_weight = user.most_permissive_role_weight_for_resource(record.group)
    invite_role_weight = record.assigned_roles.map { |role| RoleHierarchy.role_weight(role) }.min || RoleHierarchy::NON_PERMISSIVE_WEIGHT

    return false if user_role_weight > invite_role_weight # invite provides more dangerous permissions than the user has

    # If neither the user nor invite has a permissive role, check if the user lacks an explicit role provided by the invite
    if user_role_weight == invite_role_weight && invite_role_weight == 1000
      return false unless (record.assigned_roles - user.roles_for_resource(record.group)).empty?
    end

    true
  end

  def create?
    new?
  end

  def edit?
    record.user == user || create?
  end

  def update?
    edit?
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role? :admin
        scope.all
      else
        group_ids = user.group_memberships.pluck(:group_id)
        scope.where(group_id: group_ids)
      end
    end
  end
end
