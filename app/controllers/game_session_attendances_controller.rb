class GameSessionAttendancesController < ApplicationController
  add_flash_types :success
  before_action :set_game_session_attendance, only: %i[edit update]
  before_action :set_game_session, only: %i[index update]
  skip_after_action :verify_authorized, only: %i[edit update]
  skip_after_action :verify_policy_scoped, only: %i[index edit update]

  # GET /game_session_attendances
  def index
    @game_session_attendances = params[:query].present? ?
                                  @game_session.game_session_attendances.search(params[:query]) :
                                  @game_session.game_session_attendances
    @pagy, @game_session_attendances = pagy(@game_session_attendances.sorted_scope, limit: 10)

    respond_to do |format|
      format.turbo_stream
    end
  end

  # GET /game_session_attendances/1/edit
  def edit
  end

  # PATCH/PUT /game_session_attendances/1
  def update
    respond_to do |format|
      if @game_session_attendance.update(game_session_attendance_params)
        format.turbo_stream
      else
        flash.now[:error] = {message: I18n.t("game_session_attendance.update.error"),
                             options: {list_items: @game_session_attendance.errors.full_messages}}
        format.turbo_stream { render "update_fail", status: :unprocessable_entity }
      end
    end
  end

  private

  def set_game_session_attendance
    @game_session_attendance = GameSessionAttendance.find(params[:id])
  end

  def set_game_session
    @game_session = @game_session_attendance&.game_session || GameSession.find(params[:game_session_id])
  end

  # Only allow a list of trusted parameters through.
  def game_session_attendance_params
    params.require(:game_session_attendance).permit(:game_session_id, :user_id, :attending)
  end
end
