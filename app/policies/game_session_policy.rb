class GameSessionPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def create?
    is_admin_or_owner? || user.has_cached_role?(:create_game_sessions, record.game_proposal)
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.game_sessions
    end
  end

  private

  def is_admin_or_owner?
    user.has_any_role_for_resource?([:admin, :owner], record.game_proposal.group) || user.has_any_role_for_resource?([:admin, :owner], record.game_proposal) || user.has_role?(:site_admin)
  end
end
