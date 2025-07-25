class GameSessionsController < ApplicationController
  include DurationSaturator
  add_flash_types :error, :success
  before_action -> { populate_duration_param([:game_session]) }, only: %i[create update]
  before_action :set_limit, only: %i[index]
  before_action :set_game_session, only: %i[show edit update destroy]
  before_action :set_game_proposal, only: %i[index new create]
  before_action :set_game_session_attendance, only: %i[show update]
  before_action :check_param_alignment, only: %i[create]
  skip_after_action :verify_policy_scoped
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # GET /game_sessions
  def index
    @game_sessions = if @game_proposal
      authorize(@game_proposal, :show?, policy_class: GameProposalPolicy)
      GameSession.for_game_proposal(params[:game_proposal_id]).limit(@limit).upcoming
    else
      Current.user.upcoming_game_sessions.limit(@limit)
    end
    @pagy, @game_sessions, = pagy(@game_sessions, limit: @limit)
    respond_to do |format|
      format.html {
        render :index, locals: {game_sessions: @game_sessions, game_proposal: @game_proposal}
      }
      format.turbo_stream {
        if @game_proposal.present?
          render "index_slim", locals: {game_sessions: @game_sessions, game_proposal: @game_proposal}
        else
          render "index", locals: {game_sessions: @game_sessions}
        end
      }
    end
  end

  # GET /game_sessions/1
  def show
  end

  # GET /game_sessions/new
  def new
    new_params = params[:game_session].present? ? GameSession::DEFAULT_PARAMS.merge(game_session_params) : GameSession::DEFAULT_PARAMS
    @game_session = authorize(@game_proposal.game_sessions.build(new_params))

    respond_to do |format|
      format.html { render :new, locals: {game_session: @game_session} }
    end
  end

  # GET /game_sessions/1/edit
  def edit
    respond_to do |format|
      format.html {
        render :edit, locals: {game_session: @game_session}
      }
    end
  end

  # POST /game_sessions
  def create
    @game_session = authorize(@game_proposal.game_sessions.build(game_session_params))

    respond_to do |format|
      if @game_session.save
        set_game_session_attendance
        format.html {
          redirect_to game_proposal_path(@game_session.game_proposal),
            success: {message: I18n.t("game_session.create.success", name: @game_session.game_name)}
        }
        format.turbo_stream { render :create }
      else
        flash.now[:error] = {message: I18n.t("game_session.create.error", name: @game_session.game_name),
                            options: {list_items: @game_session.errors.full_messages}}
        set_proposal_options
        format.html {
          render :new, locals: {game_session: @game_session}, status: :unprocessable_entity
        }
        format.turbo_stream {
          render :new, status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /game_sessions/1
  def update
    respond_to do |format|
      if @game_session.update(game_session_params)
        notification = {message: I18n.t("game_session.update.success", name: @game_session.game_name),
                        options: {highlight: " #{@game_session.game_name} "}}
        format.html { redirect_to game_proposal_path(@game_session.game_proposal), success: notification }
        format.turbo_stream {
          flash.now[:success] = notification
          render :update
        }
      else
        flash.now[:error] = {message: I18n.t("game_session.update.error", name: @game_session.game_name),
                             options: {list_items: @game_session.errors.full_messages}}
        format.html {
          render :edit, locals: {game_session: @game_session}, status: :unprocessable_entity
        }
        format.turbo_stream {
          render :edit, status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /game_sessions/1
  def destroy
    @game_session.destroy!
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_limit
    @limit = params[:limit] || GameSession::PAGE_LIMIT
  end

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id]) if params[:game_proposal_id].present?
  end

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

  def check_param_alignment
    if params[:game_session][:game_proposal_id].to_i != @game_proposal.id
      render json: {error: "Game Proposal ID does not match the current game proposal."}, status: :unprocessable_entity
    end
  end

  def set_proposal_options
    if params[:use_groups].present?
      @groups = Current.user.game_proposals_user_can_create_sessions_for.map(&:group).uniq
    elsif params[:single_group].present?
      @game_proposals = @game_session.group.game_proposals
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
        ], status: :not_found
      }
    end
  end
end
