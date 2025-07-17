class GamesController < ApplicationController
  before_action :set_game, only: %i[show]
  skip_after_action :verify_authorized, :verify_policy_scoped

  # GET /games
  def index
    @games = params[:query].present? ? Game.search_name(params[:query]) : Game.get_popular
    @pagy, @games = pagy(@games, items: 30)
    respond_to do |format|
      format.html { render :index, locals: {games: @games} }
      format.turbo_stream
    end
  end

  # GET /games/:id or /games/:id.json
  def show
    respond_to do |format|
      format.html {
        render partial: "games/game",
          locals: option_params.to_h.symbolize_keys.merge(game: @game)
      }
      format.json { render json: @game, location: @game }
      format.turbo_stream {
        render turbo_stream: turbo_stream.update(turbo_frame_request_id,
          partial: "games/game",
          locals: option_params.to_h.symbolize_keys.merge(game: @game))
      }
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def option_params
    params.slice(:only_art, :img_size, :img_classes).permit(:only_art, :img_size, :img_classes)
  end
end
