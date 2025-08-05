module Restrictable
  extend ActiveSupport::Concern

  class_methods do
    # Sets the minimum role weight required to edit this resource (MIN_PERMISSION_EDIT_WEIGHT).
    # @param min_weight defaults to RoleHierarchy::NON_PERMISSIVE_WEIGHT
    def restrict(min_weight: RoleHierarchy::NON_PERMISSIVE_WEIGHT)
      const_set(:MIN_PERMISSION_EDIT_WEIGHT, min_weight)
    end
  end

  included do
    # @param users [Array<User>] the users to create the permission set for.
    # @return [PermissionSet] the permission set where attribute users_roles has the user ids as keys with user and role ids as values. e.g.  { 1 => { user: User, role_ids: [1, 2, 3] }}
    def make_permission_set(users)
      # Build roles for each user
      current_roles = users.each_with_object({}) do |user, hash|
        hash[user.id] = {
          user: user,
          role_ids: user.roles_for_resource(self).pluck(:id).to_a || [],
          username: user.username
        }
      end
      # Create a new instance with the calculated roles
      PermissionSet.new(
        resource: self,
        users_roles: current_roles
      )
    end
  end
end
