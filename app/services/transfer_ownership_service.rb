# frozen_string_literal: true

# Transfers the ownership of a resource (e.g., Group, GameProposal) from one user to another using Rolify roles.
#
# The current owner is identified by finding the user with the `:owner` role
# scoped to the provided resource.
#
# @example Transferring ownership of a GameProposal
#   new_owner = User.find(params[:new_owner_id])
#   proposal = GameProposal.find(params[:id])
#   TransferOwnershipService.call(new_owner, proposal)
class TransferOwnershipService < ApplicationService
  # @param new_owner [User] The user who will become the new owner.
  # @param resource [ActiveRecord::Base] The resource whose ownership will be transferred (must have Rolify included).
  def initialize(new_owner, resource)
    @current_owner = User.with_role(:owner, resource).first
    @new_owner = new_owner
    @resource = resource
  end

  # Executes the ownership transfer.
  # Removes the `:owner` role from the current owner (if found) and grants
  # the `:owner` role to the new owner for the specified resource.
  #
  # @return [void]
  def call
    @current_owner&.remove_role(:owner, @resource)
    @new_owner.add_role(:owner, @resource)
  end
end
