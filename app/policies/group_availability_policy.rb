class GroupAvailabilityPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def edit?
    record.user == user
  end

  def update?
    record.user == user
  end

  def destroy?
    record.user == user
  end

  def create?
    record.user == user
  end

  def show?
    record.user == user
  end

  def new?
    record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      if user.has_cached_role?(:admin)
        scope.all
      else
        user.group_availabilities
      end
    end
  end
end
