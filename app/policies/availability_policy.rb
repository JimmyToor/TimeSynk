class AvailabilityPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def new?
    record.user == user
  end

  def show?
    record.user == user || user.has_role?(:site_admin)
  end

  def create?
    user == record.user
  end

  def edit?
    create?
  end

  def update?
    edit?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.availabilities
    end
  end
end
