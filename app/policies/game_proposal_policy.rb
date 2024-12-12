class GameProposalPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def new?
    is_group_owner_or_admin? || user.has_any_role_for_resource?([:manage_all_proposals, :create_game_proposals], record.group)
  end

  def create?
    new?
  end

  def show?
    user.groups.include?(record.group)
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end

  def create_game_session?
    is_group_owner_or_admin? || user.has_cached_role?(:create_game_sessions, record)
  end

  def change_owner?
    user.has_cached_role?(:owner, record) || user.has_any_role_for_resource?([:owner,:admin], record.group) || user.has_cached_role?(:site_admin)
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.game_proposals
    end
  end

  private

  def is_group_owner_or_admin?
    user.has_any_role_for_resource?([:admin, :owner], record.group)
  end
end
