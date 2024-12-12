class GameSessionsController < ApplicationController
  before_action :set_game_session, only: %i[ show edit update destroy ]
  before_action :set_game_proposal, only: %i[ new create ]
  before_action :set_game_session_attendance, only: %i[ show update ]
  skip_after_action :verify_policy_scoped

  # GET /game_sessions or /game_sessions.json
  def index
    @game_sessions = if params[:game_proposal_id]
      GameSession.for_game_proposal(params[:game_proposal_id])
    else
      policy_scope(GameSession)
    end
    authorize @game_sessions
  end

  # GET /game_sessions/1 or /game_sessions/1.json
  def show
  end

  # GET /game_sessions/new
  def new
    @game_session = @game_proposal.game_sessions.build(date: Time.current.utc.iso8601, duration: 1.hour)
    game_proposals = params[:single_game_proposal] ? nil : @game_proposal.group.game_proposals

    respond_to do |format|
      format.html { render :new, locals: {game_session: @game_session, initial_game_proposal: @game_proposal, game_proposal: @game_proposal, game_proposals: game_proposals }}
      format.turbo_stream {
        Current.user.add_role(:owner, @game_session)
        render turbo_stream: turbo_stream.replace(
          "game_session_form",
          partial: "game_sessions/form",
          locals: {game_session: @game_session, game_proposal: @game_proposal, game_proposals: game_proposals})
      }
    end
  end

  # GET /game_sessions/1/edit
  def edit
    respond_to do |format|
      format.html { 
        render :edit, locals: {game_session: @game_session,
                                           initial_game_proposal: @game_session.game_proposal,
                                           game_proposals: @game_session.game_proposal.group.game_proposals,
                                           groups: Current.user.groups} }
    end
  end

  # POST /game_sessions or /game_sessions.json
  def create
    # TODO: Don't allow users to make sessions for another proposal i.e. game_proposal_id in strong params should match the current proposal's id (from the url params).
    @game_session = @game_proposal.game_sessions.build(game_session_params)
    respond_to do |format|
      if @game_session.save
        set_game_session_attendance
        Current.user.add_role(:owner, @game_session)
        format.html { redirect_to game_proposal_url(@game_session.game_proposal), notice: "Game session was successfully created." }
        format.json { render :show, status: :created, location: @game_session }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.refresh(
            "game_session_form",
            partial: "game_sessions/form",
            locals: {game_session: @game_session, game_proposal: @game_proposal, game_proposals: @game_proposal.group.game_proposals, groups: Current.user.groups}
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
        format.turbo_stream
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
      format.turbo_stream
    end
  end

  private

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id])
  end
    
    # Use callbacks to share common setup or constraints between actions.
  def set_game_session
    @game_session = GameSession.find(params[:id])
    authorize @game_session
  end

  def set_game_session_attendance
    @game_session_attendance = @game_session.get_or_build_attendance_for_user(Current.user)
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  #`duration` is length of time in minutes
  def game_session_params
    params.require(:game_session).permit(:game_proposal_id, :date, :duration, :duration_hours, :duration_minutes).tap do |whitelisted|
      if whitelisted[:duration_hours].present? && whitelisted[:duration_minutes].present? && !whitelisted[:duration].present?
        whitelisted[:duration] = whitelisted[:duration_hours].to_i.hours + whitelisted[:duration_minutes].to_i.minutes
      end
      whitelisted.delete(:duration_hours)
      whitelisted.delete(:duration_minutes)
    end
  end
end
