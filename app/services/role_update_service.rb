# frozen_string_literal: true

# Adds and removes for a specific User using Rolify.
#
# @raise [ArgumentError] If any of the provided role IDs in `add_roles` or
#   `remove_roles` do not correspond to existing Role records.
#
# @example Adding role ID 1 and removing role ID 3 for a user
#   user = User.find(1)
#   RoleUpdateService.call(user, [1], [3])
class RoleUpdateService < ApplicationService
  # Initializes the service, validating role IDs.
  # Blank IDs are rejected, and IDs are converted to integers within Sets.
  #
  # @param user [User] The user whose roles are being updated.
  # @param add_roles [Array<Integer, String>] An array of Role IDs to add to the user.
  # @param remove_roles [Array<Integer, String>] An array of Role IDs to remove from the user.
  # @raise [ArgumentError] If validation fails (invalid role ID found).
  def initialize(user, add_roles = [], remove_roles = [])
    @add_roles = Set.new(add_roles.reject(&:blank?).map(&:to_i)) if add_roles.present?
    @remove_roles = Set.new(remove_roles.reject(&:blank?).map(&:to_i)) if remove_roles.present?
    @user = user
    validate_role_ids!
  end

  # Executes the role update process within a transaction.
  # Adds roles from the `@add_roles` set that the user doesn't already have.
  # Removes roles specified in the `@remove_roles` set from the user.
  # Logs the update operation at the debug level.
  #
  # @return [void]
  def call
    ActiveRecord::Base.transaction do
      # Add roles that are in the add_roles set but not already assigned to the user
      @user.roles << Role.where(id: @add_roles - @user.roles.pluck(:id)) if @add_roles.present?
      # Remove roles specified in the remove_roles set
      @user.roles.delete(Role.where(id: @remove_roles)) if @remove_roles.present?
    end
    Rails.logger.debug "Roles updated for user #{@user.username} with add_roles: #{@add_roles}, remove_roles: #{@remove_roles}"
  end

  private

  # Validates that all provided role IDs exist in the database.
  # Queries for roles matching the IDs in `@add_roles` and `@remove_roles`.
  #
  # @raise [ArgumentError] If `ActiveRecord::RecordNotFound` is raised during the query,
  #   indicating an invalid role ID was provided.
  # @return [void]
  def validate_role_ids!
    # Use `find` which raises RecordNotFound if any ID is invalid
    Role.find(@add_roles.to_a) if @add_roles.present?
    Role.find(@remove_roles.to_a) if @remove_roles.present?
  rescue ActiveRecord::RecordNotFound => e
    # Re-raise as ArgumentError for better service-level error handling
    raise ArgumentError, "Invalid role ID provided: #{e.message}"
  end
end
