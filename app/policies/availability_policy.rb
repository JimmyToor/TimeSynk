class AvailabilityPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def show?
    record.user == user || user.has_role?(:admin)
  end

  def edit?
    record.user == user || user.has_role?(:admin)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:admin)
        scope.all
      else
        user.availabilities
      end
    end
  end
end
