# frozen_string_literal: true

# Creates a new Group, adding the creator as the initial member with the 'owner' role, and setting up default group roles.
#
# Inherits from ApplicationService.
#
# @example Creating a new group
#   params = ActionController::Parameters.new(name: 'New Group', description: 'A new group', group_type: 'public').permit(:name, :description, :group_type)
#   user = User.find(1)
#   new_group = GroupCreationService.call(params, user)
class GroupCreationService < ApplicationService
  # Initializes the service with group parameters and the creator user.
  #
  # @param params [ActionController::Parameters] Permitted parameters for creating the group.
  # @option params [String] :name The name of the group (required).
  # @option params [String] :description The description of the group.
  # @option params [String] :group_type The type of the group (e.g., 'public', 'private').
  # @param user [User] The user who is creating the group.
  #
  # @return [Group] The newly created group.
  def initialize(params, user)
    @params = params
    @user = user
  end

  # Executes the group creation process within a transaction.
  # Creates the group, adds the creator as a member, creates default roles,
  # assigns the owner role to the creator, and handles potential errors.
  #
  # @return [Group] The newly created group (with errors if creation failed).
  def call
    @group = Group.new(@params)
    ActiveRecord::Base.transaction do
      @group.save!
      @group.users << @user
      @group.create_roles

      @user.add_role :owner, @group
    rescue ActiveRecord::RecordInvalid => e
      if e.record != @group # Don't need to add group validation errors since they are already added
        @group.errors.add(:base, e.message)
      end
    rescue => e
      @group.errors.add(:base, e.message)
    end
    @group
  end
end
