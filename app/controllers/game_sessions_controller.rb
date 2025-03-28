class GameSessionsController < ApplicationController
  include DurationSaturator
  before_action -> { populate_duration_param([:game_session]) }, only: %i[create update]
  before_action :set_game_session, only: %i[show edit update destroy]
  before_action :set_game_proposal, only: %i[new create]
  before_action :set_game_session_attendance, only: %i[show update]
  before_action :check_param_alignment, only: %i[create]
  skip_after_action :verify_policy_scoped

  # GET /game_sessions or /game_sessions.json
  def index
    @game_sessions = if params[:game_proposal_id]
      GameSession.for_game_proposal(params[:game_proposal_id])
    else
      Current.user.upcoming_game_sessions
    end
    @pagy, @game_sessions, = pagy(@game_sessions, limit: 8)
    authorize @game_sessions
  end

  # GET /game_sessions/1 or /game_sessions/1.json
  def show
  end

  # GET /game_sessions/new
  def new
    @game_session = @game_proposal.game_sessions.build(GameSession::DEFAULT_PARAMS)
    authorize @game_session
    game_proposals = params[:single_game_proposal] ? nil : @game_proposal.group.game_proposals

    respond_to do |format|
      format.html { render :new, locals: {game_session: @game_session, game_proposals: game_proposals} }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "game_session_form",
          partial: "game_sessions/form",
          locals: {game_session: @game_session, game_proposal: @game_proposal, game_proposals: game_proposals}
        )
      }
    end
  end

  # GET /game_sessions/1/edit
  def edit
    respond_to do |format|
      format.html {
        render :edit, locals: {game_session: @game_session, groups: Current.user.groups}
      }
    end
  end

  # POST /game_sessions or /game_sessions.json
  def create
    @game_session = authorize @game_proposal.game_sessions.build(game_session_params)
    game_proposals = params[:single_game_proposal] ? nil : @game_proposal.group.game_proposals

    respond_to do |format|
      if @game_session.save
        set_game_session_attendance
        Current.user.add_role(:owner, @game_session)
        format.html { redirect_to game_proposal_url(@game_session.game_proposal), notice: "Game session created." }
        format.json { render :show, status: :created, location: @game_session }
        format.turbo_stream
      else
        format.html {
          redirect_to new_game_proposal_game_session_path(@game_proposal),
            game_session: @game_session,
            game_proposals: game_proposals,
            status: :unprocessable_entity
        }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "form_game_session",
            partial: "game_sessions/form",
            locals: {game_session: @game_session,
                     initial_game_proposal: @game_proposal,
                     game_proposal: @game_proposal,
                     game_proposals: game_proposals,
                     groups: Current.user.groups}
          ), status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /game_sessions/1 or /game_sessions/1.json
  def update
    respond_to do |format|
      if @game_session.update(game_session_params)
        format.html { redirect_to game_proposal_url(@game_session.game_proposal), notice: "Game session was successfully updated." }
        format.json { render :show, status: :ok, location: @game_session }
        format.turbo_stream
      else
        format.html { render :edit, game_session: @game_session, groups: Current.user.groups, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "form_game_session",
            partial: "game_sessions/form",
            locals: {game_session: @game_session,
                     initial_game_proposal: @game_session.game_proposal,
                     game_proposals: @game_session.game_proposal.group.game_proposals,
                     groups: Current.user.groups}
          ), status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /game_sessions/1 or /game_sessions/1.json
  def destroy
    game_proposal = @game_session.game_proposal
    @game_session.destroy!
    respond_to do |format|
      format.html { redirect_to game_proposal, notice: "Game session was successfully destroyed." }
      format.turbo_stream
    end
  end

  private

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_game_session
    @game_session = authorize(GameSession.find(params[:id]))
  end

  def set_game_session_attendance
    @game_session_attendance = @game_session.get_or_build_attendance_for_user(Current.user)
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def game_session_params
    params.require(:game_session).permit(:game_proposal_id, :date, :duration, :duration_days, :duration_hours, :duration_minutes)
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def check_param_alignment
    if params[:game_session][:game_proposal_id].to_i != @game_proposal.id
      render json: {error: "Game Proposal ID does not match the current game proposal."}, status: :unprocessable_entity
    end
  end
end
