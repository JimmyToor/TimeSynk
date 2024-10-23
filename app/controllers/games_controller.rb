class GamesController < ApplicationController
  before_action :set_game, only: %i[ show ]
  skip_after_action :verify_authorized, :verify_policy_scoped

  # GET /games or /games.json
  def index
    @games = Game.get_popular
  end

  def show
    respond_to do |format|
      format.html { render partial: "games/game", locals: { game: Game.find(params[:id]) } }
      format.json { render json: @game, location: @game }
      format.turbo_stream {
        render turbo_stream: turbo_stream.update( response.headers["Turbo-Frame"], partial: "games/game", locals: { game: @game })
      }
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def game_params
    params.fetch(:game, {})
  end

  def set_game
    @game = Game.find(params[:id])
  end
end
