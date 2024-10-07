class HomeController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  def index
    @proposals = policy_scope(GameProposal)
    @groups = policy_scope(Group)
    @game_sessions = policy_scope(GameSession)
  end
end
