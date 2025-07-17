module OwnershipsHelper
  # Returns the path for transferring ownership of a resource.
  def transfer_ownership_path(resource)
    if resource.is_a?(Group)
      group_transfer_ownership_path(resource)
    elsif resource.is_a?(GameProposal)
      game_proposal_transfer_ownership_path(resource)
    elsif resource.is_a?(GameSession)
      game_session_transfer_ownership_path(resource)
    else
      raise ArgumentError, "Unsupported resource type for ownership transfer"
    end
  end
end
