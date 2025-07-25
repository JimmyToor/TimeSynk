class GroupPolicy < ApplicationPolicy
  def show?
    user.has_cached_role?(:site_admin) || record.is_user_member?(user)
  end

  def create?
    true
  end

  def edit?
    user.has_cached_role?(:owner, record)
  end

  def update?
    edit?
  end

  def destroy?
    user.has_cached_role?(:owner, record)
  end

  def create_game_proposal?
    user.has_any_role_for_resource?([:owner, :admin, :create_game_proposals], record)
  end

  def create_invite?
    user.has_any_role_for_resource?([:owner, :admin, :manage_invites], record)
  end

  def transfer_ownership?
    user.has_cached_role?(:owner, record) || user.has_cached_role?(:site_admin)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.groups
    end
  end
end
