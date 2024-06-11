class GameSessionAttendancesController < ApplicationController
  before_action :set_game_session_attendance, only: %i[ show edit update destroy ]

  # GET /game_session_attendances or /game_session_attendances.json
  def index
    @game_session_attendances = GameSessionAttendance.all
  end

  # GET /game_session_attendances/1 or /game_session_attendances/1.json
  def show
  end

  # GET /game_session_attendances/new
  def new
    @game_session_attendance = GameSessionAttendance.new
  end

  # GET /game_session_attendances/1/edit
  def edit
  end

  # POST /game_session_attendances or /game_session_attendances.json
  def create
    @game_session_attendance = GameSessionAttendance.new(game_session_attendance_params)

    respond_to do |format|
      if @game_session_attendance.save
        format.html { redirect_to game_session_attendance_url(@game_session_attendance), notice: "Session attendance was successfully created." }
        format.json { render :show, status: :created, location: @game_session_attendance }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game_session_attendance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /game_session_attendances/1 or /game_session_attendances/1.json
  def update
    respond_to do |format|
      if @game_session_attendance.update(game_session_attendance_params)
        format.html { redirect_to game_session_attendance_url(@game_session_attendance), notice: "GameSession attendance was successfully updated." }
        format.json { render :show, status: :ok, location: @game_session_attendance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_session_attendance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /session_attendances/1 or /session_attendances/1.json
  def destroy
    @game_session_attendance.destroy!

    respond_to do |format|
      format.html { redirect_to game_session_attendances_url, notice: "Session attendance was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_session_attendance
      @game_session_attendance = GameSessionAttendance.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def game_session_attendance_params
      params.require(:game_session_attendance).permit(:game_session_id, :user_id, :attending)
    end
end
