class InvitePolicy < ApplicationPolicy

  def index?
    user.has_role? :admin
  end

  def new?
    user.has_role?(:site_admin) || record.group.users.include?(user)
  end

  def show?
    user.has_role?(:site_admin) || record.group.users.include?(user)
  end

  def create?
    user.has_role?(:site_admin) || record.group.users.include?(user)
  end

  def update?
    user.has_role?(:site_admin) || record.group.users.include?(user)
  end

  def destroy?
    user.has_role?(:site_admin) || record.group.users.include?(user)
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
