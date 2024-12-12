# frozen_string_literal: true

class TransferOwnershipService
  # Initializes a new instance of the TransferOwnershipService.
  #
  # @param new_owner [User] The user who will become the new owner.
  # @param resource [Resource] The resource whose ownership will be transferred.
  def initialize(new_owner, resource)
    @current_owner = User.with_role(:owner, resource).first
    @new_owner = new_owner
    @resource = resource
  end

  def transfer_ownership
    @current_owner.remove_role(:owner, @resource)
    @new_owner.add_role(:owner, @resource)
  end
end
