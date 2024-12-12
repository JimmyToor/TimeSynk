# frozen_string_literal: true

class RoleUpdateService

  # Initializes a new instance of the RoleUpdateService.
  #
  # @param user [User] The user whose roles are being updated.
  # @param add_roles [Array<Integer>] The role IDs to add to the user.
  # @param remove_roles [Array<Integer>] The role IDs to remove from the user.
  def initialize(user:, add_roles: [], remove_roles: [])
    @add_roles = add_roles.reject(&:blank?).map(&:to_i) if add_roles.present?
    @remove_roles = remove_roles.reject(&:blank?).map(&:to_i) if remove_roles.present?
    @user = user
    validate_role_ids!
  end

  def update_roles
    ActiveRecord::Base.transaction do
      @user.roles << Role.where(id: @add_roles - @user.roles.pluck(:id))if @add_roles.present?
      @user.roles.delete(Role.where(id: @remove_roles)) if @remove_roles.present?
    end
  end

  private

  def validate_role_ids!
    Role.where(id: @add_roles) if @add_roles.present?
    Role.where(id: @remove_roles) if @remove_roles.present?
  rescue ActiveRecord::RecordNotFound => e
    raise ArgumentError, "Invalid role ID provided: #{e.message}"
  end

end
