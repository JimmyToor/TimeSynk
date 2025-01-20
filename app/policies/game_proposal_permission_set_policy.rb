class GameProposalPermissionSetPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  def edit?
    is_at_least_group_admin? || is_game_proposal_owner_or_admin?
  end

  # Expects a PermissionSet object with a resource of a GameProposal and a hash of user IDs. Hash values and other keys are ignored.
  def update?
    # only admins and owners for the group or game proposal can change roles for others, and only for users with lower permissions
    # site_admin > group_owner > group_admin > game_proposal_owner > game_proposal_admin > others

    # Check if the user has the necessary permissions
    return true if is_site_admin_or_group_owner?
    return false unless user.has_cached_role?(:admin, record.resource.group) || user.has_any_role_for_resource?([:admin,:owner], record.resource)

    record.users_roles.each do |user_id, _|
      return false if user_id == user.id
      return false unless user.supersedes_user_in_game_proposal?(User.find(user_id), record.resource)
    end

    true
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  private

  def is_at_least_group_admin?
    user.has_cached_role?(:site_admin) || user.has_any_role_for_resource?([:admin, :owner], record.resource.group)
  end

  def is_game_proposal_owner_or_admin?
    user.has_cached_role?(:owner, record.resource) || user.has_cached_role?(:admin, record.resource)
  end

  def is_site_admin_or_group_owner?
    user.has_cached_role?(:site_admin) || user.has_cached_role?(:owner, record.resource.group)
  end
end
