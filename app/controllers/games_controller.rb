class GamesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_authorized, :verify_policy_scoped

  # GET /games or /games.json
  def index
    @games = Game.get_popular
    Rails.logger.debug "Games: #{@games.inspect}"
  end

  private
    # Only allow a list of trusted parameters through.
    def game_params
      params.fetch(:game, {})
    end
end
