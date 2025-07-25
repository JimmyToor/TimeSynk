class HomeController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    @game_proposals = policy_scope(GameProposal)
    @groups = policy_scope(Group)
    respond_to do |format|
      format.html {
        render :index,
          locals: {game_proposals: @game_proposals,
                   game_proposal: @game_proposals.first,
                   groups: @groups,
                   pending_game_proposals: Current.user.pending_game_proposals},
          status: :ok
      }
    end
  end
end
