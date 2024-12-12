class InvitePolicy < ApplicationPolicy

  def index?
    user.has_role? :admin
  end

  def new?
    user.has_role?(:site_admin) || user.has_any_role_for_resource?([:owner, :admin, :manage_invites], record.group)
  end

  def show?
    user.has_role?(:site_admin) || record.group.users.include?(user)
  end

  def create?
    new?
  end

  def update?
    create?
  end

  def edit?
    update?
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
