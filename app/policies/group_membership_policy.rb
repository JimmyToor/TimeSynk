class GroupMembershipPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def show?
    user.has_cached_role?(:site_admin) || record.group.is_user_member?(user)
  end

  def create?
    user.has_cached_role?(:site_admin)
  end

  def destroy?
    return false if record.user.has_role?(:owner, record.group)
    user_has_kick_permission? || user === record.user
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  private

  def user_has_kick_permission?
    user.has_cached_role?(:site_admin) || user.has_any_role_for_resource?([:owner, :admin, :kick_users], record.group)
  end
end
