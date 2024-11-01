class GameSessionsController < ApplicationController
  before_action :set_game_session, only: %i[ show edit update destroy ]
  before_action :set_game_proposal, only: %i[ new create ]
  before_action :set_game_session_attendance, only: %i[ show ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /game_sessions or /game_sessions.json
  def index
    @game_sessions = if params[:game_proposal_id]
      GameSession.for_game_proposal(params[:game_proposal_id])
    else
      GameSession.for_current_user_groups
    end
  end

  # GET /game_sessions/1 or /game_sessions/1.json
  def show
  end

  # GET /game_sessions/new
  def new
    @game_session = @game_proposal.game_sessions.build(user_id: Current.user.id, date: Time.now.iso8601)

    respond_to do |format|
      format.html { render :new, locals: {game_session: @game_session, game_proposal: @game_proposal, game_proposals: @game_proposal.group.game_proposals }}
      format.turbo_stream {
        render turbo_stream: turbo_stream.update(
          "game_session_form",
          partial: "game_sessions/form",
          locals: {game_session: @game_session, game_proposal: @game_proposal, game_proposals: @game_proposal.group.game_proposals})
      }
    end
  end

  # GET /game_sessions/1/edit
  def edit
    respond_to do |format|
      format.html { render :edit, locals: {game_session: @game_session, game_proposal: @game_session.game_proposal, game_proposals: @game_session.game_proposal.group.game_proposals }}
    end
  end

  # POST /game_sessions or /game_sessions.json
  def create
    # TODO: Don't allow users to make sessions in other users' names i.e. user_id should be the current user's id
    # TODO: Don't allow users to make sessions for another proposal i.e. game_proposal_id in strong params should match the current proposal's id (from the url params).
    @game_session = @game_proposal.game_sessions.build(game_session_params)
    respond_to do |format|
      if @game_session.save
        @game_session.create_roles
        format.html { redirect_to game_session_url(@game_session), notice: "Game session was successfully created." }
        format.json { render :show, status: :created, location: @game_session }
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.update(
              "game_session_form",
              partial: "game_sessions/form",
              locals: {game_proposal: @game_proposal, game_session: GameSession.new(game_proposal: @game_proposal),
                       game_proposals: @game_proposal.group.game_proposals}
            ),
            turbo_stream.update(
              @game_proposal,
              partial: "game_sessions/game_session",
              locals: {game_session: @game_session}
            )
          ]
        }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update(
            "game_session_form",
            partial: "game_sessions/form",
            locals: {game_session: @game_session, game_proposal: @game_proposal, game_proposals: @game_proposal.group.game_proposals}
          ), status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /game_sessions/1 or /game_sessions/1.json
  def update
    respond_to do |format|
      if @game_session.update(game_session_params)
        format.html { redirect_to game_session_url(@game_session), notice: "Game session was successfully updated." }
        format.json { render :show, status: :ok, location: @game_session }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update(
            @game_session,
            partial: "game_sessions/game_session",
            locals: {game_session: @game_session, game_proposals: @game_session.game_proposal.group.game_proposals})
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /game_sessions/1 or /game_sessions/1.json
  def destroy
    @game_session.destroy!
    respond_to do |format|
      format.html { redirect_to game_sessions_url, notice: "Game session was successfully destroyed." }
      format.json { head :no_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.remove(@game_session)
      }
    end
  end

  private

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id])
  end
    
    # Use callbacks to share common setup or constraints between actions.
  def set_game_session
    @game_session = GameSession.find(params[:id])
  end

  def set_game_session_attendance
    @game_session_attendance = @game_session.user_get_or_build_attendance(Current.user)
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

    # Only allow a list of trusted parameters through.
  def game_session_params
    params.require(:game_session).permit(:game_session_id, :game_proposal_id, :user_id, :date, :duration)
  end
end
