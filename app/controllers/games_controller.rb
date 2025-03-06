class GamesController < ApplicationController
  before_action :set_game, only: %i[show]
  skip_after_action :verify_authorized, :verify_policy_scoped

  # GET /games or /games.json
  def index
    @games = params[:query].present? ? Game.search_name(params[:query]) : Game.get_popular
    @pagy, @games = pagy(@games, items: 30)
    respond_to do |format|
      format.html { render :index, locals: {games: @games} }
      format.turbo_stream
      format.json { render json: @games }
    end
  end

  def show
    respond_to do |format|
      format.html {
        render partial: "games/game",
          locals: {game: @game,
                   only_art: params[:only_art] || nil,
                   img_size: params[:img_size] || nil,
                   img_classes: params[:img_classes] || nil}
      }
      format.json { render json: @game, location: @game }
      format.turbo_stream {
        render turbo_stream: turbo_stream.update(response.headers["Turbo-Frame"], partial: "games/game", locals: {game: @game})
      }
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end
end
