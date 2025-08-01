class GameSessionPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def create?
    user.has_any_role_for_resource?([:owner, :admin, :create_game_sessions, :manage_all_game_sessions], record.game_proposal) ||
      user.has_any_role_for_resource?([:owner, :admin, :manage_all_game_proposals], record.game_proposal.group)
  end

  def show?
    user.groups.include?(record.game_proposal.group)
  end

  def new?
    create?
  end

  def edit?
    user.has_any_role_for_resource?([:owner], record) ||
      user.has_any_role_for_resource?([:owner, :admin, :manage_all_game_sessions], record.game_proposal) ||
      user.has_any_role_for_resource?([:owner, :admin, :manage_all_game_proposals], record.game_proposal.group)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def transfer_ownership?
    user.has_cached_role?(:owner, record) ||
      user.has_any_role_for_resource?([:admin, :owner, :manage_all_game_sessions], record.game_proposal) ||
      user.has_any_role_for_resource?([:admin, :owner, :manage_all_game_proposals], record.group)
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.game_sessions
    end
  end
end
