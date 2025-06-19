class InvitePolicy < ApplicationPolicy
  def new?
    user.has_any_role_for_resource?([:owner, :admin, :manage_invites], record.group)
  end

  # Prevents users from accessing invites that could give them more permissions than they already have
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
    return false unless new?
    return true if record.assigned_role_ids.blank?
    record.user_can_change_roles?(record.assigned_role_ids)
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
      return scope unless scope.any?

      # This is only used for the index view so we can assume scope is limited to a single group
      user_role_weight = @user.most_permissive_role_weight_for_resource(scope.first.group)
      user_group_roles = @user.roles_for_resource(scope.first.group)

      allowed_invite_ids = []
      active_invites = scope.where("expires_at >= ?", Time.current)
      active_invites.each do |invite|
        allowed_invite_ids << invite.id if can_see_invite?(invite, user_role_weight, user_group_roles)
      end

      scope.where(id: allowed_invite_ids)
    end

    private

    def can_see_invite?(invite, user_role_weight, user_group_roles)
      invite_role_weight = invite.assigned_roles.map { |role| RoleHierarchy.role_weight(role) }.min || RoleHierarchy::NON_PERMISSIVE_WEIGHT

      return false if user_role_weight > invite_role_weight # invite provides more dangerous permissions than the user has

      # If neither the user nor invite has a permissive role, check if the user lacks an explicit role provided by the invite
      if user_role_weight == invite_role_weight && invite_role_weight == RoleHierarchy::NON_PERMISSIVE_WEIGHT
        return false unless (invite.assigned_roles - user_group_roles).empty?
      end

      true
    end
  end
end
