class GroupMembershipPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def show?
    user.has_role?(:site_admin) || record.group.is_user_member?(user)
  end

  def create?
    true
  end

  def destroy?
    return true if user === record.user && user.has_cached_role?(:owner, record)
    user.has_cached_role?(:kick_users, record.group) || user_is_owner_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  private

  def user_is_owner_or_admin?
    user.has_cached_role?(:site_admin) || (user.has_any_role_for_resource?([:owner, :admin], record.group) && user.supersedes_user_in_group?(record.user, record.group))
  end
end
