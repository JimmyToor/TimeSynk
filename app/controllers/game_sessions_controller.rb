class GameSessionsController < ApplicationController
  include DurationSaturator
  add_flash_types :error, :success
  before_action -> { populate_duration_param([:game_session]) }, only: %i[create update]
  before_action :set_game_session, only: %i[show edit update destroy]
  before_action :set_game_proposal, only: %i[new create]
  before_action :set_game_session_attendance, only: %i[show update]
  before_action :check_param_alignment, only: %i[create]
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized, only: %i[new]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # GET /game_sessions or /game_sessions.json
  def index
    if params[:game_proposal_id]
      @game_sessions = GameSession.for_game_proposal(params[:game_proposal_id])
      set_game_proposal
    else
      @game_sessions = Current.user.upcoming_game_sessions
    end
    @pagy, @game_sessions, = pagy(@game_sessions, limit: 8)
    authorize @game_sessions
    respond_to do |format|
      format.html {
        render :index, locals: {game_sessions: @game_sessions, upcoming: !params[:game_proposal_id].present?}
      }
      format.json
    end
  end

  # GET /game_sessions/1 or /game_sessions/1.json
  def show
  end

  # GET /game_sessions/new
  def new
    new_params = params[:game_session].present? ? GameSession::DEFAULT_PARAMS.merge(game_session_params) : GameSession::DEFAULT_PARAMS
    @game_session = @game_proposal.game_sessions.build(new_params)
    game_proposals = params[:single_game_proposal] ? nil : @game_proposal.group.game_proposals

    respond_to do |format|
      format.html { render :new, locals: {game_session: @game_session, game_proposals: game_proposals} }
      format.turbo_stream
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
        format.html {
          redirect_to game_proposal_url(@game_session.game_proposal),
            success: {message: I18n.t("game_session.create.success"),
                      options: {highlight: " #{@game_session.game_name} "}}
        }
        format.json { render :show, status: :created, location: @game_session }
        format.turbo_stream
      else
        format.html {
          redirect_to new_game_proposal_game_session_path(@game_proposal),
            game_session: @game_session,
            game_proposals: game_proposals,
            error: {message: I18n.t("game_session.create.error", name: @game_session.game_name),
                    options: {list_items: @game_session.errors.full_messages}},
            status: :unprocessable_entity
        }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
        format.turbo_stream {
          flash.now[:error] = {message: I18n.t("game_session.create.error", name: @game_session.game_name),
                                options: {list_items: @game_session.errors.full_messages}}
          render "create_fail", status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /game_sessions/1 or /game_sessions/1.json
  def update
    respond_to do |format|
      if @game_session.update(game_session_params)
        format.html {
          redirect_to game_proposal_url(@game_session.game_proposal),
            success: {message: I18n.t("game_session.update.success", name: @game_session.game_name),
                      options: {highlight: " #{@game_session.game_name} "}}
        }
        format.json { render :show, status: :ok, location: @game_session }
        format.turbo_stream
      else
        format.html {
          flash[:error] = {message: I18n.t("game_session.update.error", name: @game_session.game_name),
                           options: {list_items: @game_session.errors.full_messages}}
          redirect_to edit_game_session_path(@game_session)
        }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
        format.turbo_stream {
          flash.now[:error] = {message: I18n.t("game_session.update.error", name: @game_session.game_name),
                               options: {list_items: @game_session.errors.full_messages}}
          render "update_fail"
        }
      end
    end
  end

  # DELETE /game_sessions/1 or /game_sessions/1.json
  def destroy
    game_proposal = @game_session.game_proposal
    @game_session.destroy!
    respond_to do |format|
      format.html {
        redirect_to game_proposal, success: {message: I18n.t("game_session.destroy.success", name: game_proposal.game_name),
                                             options: {highlight: " #{@game_session.game_name} "}}
      }
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

  def user_not_authorized_to_create
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def check_param_alignment
    if params[:game_session][:game_proposal_id].to_i != @game_proposal.id
      render json: {error: "Game Proposal ID does not match the current game proposal."}, status: :unprocessable_entity
    end
  end

  def record_not_found
    respond_to do |format|
      format.html {
        flash.now[:error] = {message: I18n.t("game_session.not_found")}
        render "shared/error", status: :not_found
      }
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace(targets: ".content_game_session_#{params[:id]}", partial: "game_sessions/destroyed"),
          turbo_stream_toast(:error, I18n.t("game_session.not_found"), "game_session_invalid")
        ]
      }
    end
  end
end
