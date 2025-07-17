# frozen_string_literal: true

class PermissionSetUpdateService < ApplicationService
  # Initializes the service with the user and the resource to update permissions for.
  # @param permission_set_params [ActionController::Parameters] The parameters containing role changes.
  # @param user [User] The user updating the permissions.
  # @param resource [ActiveRecord::Base] The resource for which permissions are being updated.
  def initialize(permission_set_params, user, resource)
    @params = permission_set_params
    @user = user
    @resource = resource
  end

  # Executes the permission update process.
  # @return [Array<User>] An array of affected users whose roles were updated.
  def call
    users_role_changes = build_role_changes_hash
    update_permissions(users_role_changes)
    @affected_users
  end

  private

  # Adds the users to their respective role changes in the role_changes hash.
  def build_role_changes_hash
    # Extract role changes from params
    role_changes = @params.dig(:role_changes).to_h.transform_keys(&:to_i) || {}

    # Get all relevant users and add them to the role changes hash
    users = User.where(id: role_changes.keys).index_by(&:id)
    @affected_users = users.values

    role_changes.each_with_object({}) do |(user_id, changes), hash|
      hash[user_id] = changes.merge(user: users[user_id])
    end
  end

  def update_permissions(users_role_changes)
    users_role_changes.each do |user_id, role_changes|
      role_user = role_changes[:user]
      role_user.update_roles(add_roles: role_changes[:add_roles], remove_roles: role_changes[:remove_roles])
    end
  end
end
