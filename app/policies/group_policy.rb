class GroupPolicy < ApplicationPolicy

  def edit?
    user.has_role?(:owner, record) || user.has_role?(:site_admin) || user.has_role?(:admin, record)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:site_admin)
        scope.all
      else
        group_ids = user.group_memberships.pluck(:group_id)
        scope.where(id: group_ids)
      end
    end
  end
end


