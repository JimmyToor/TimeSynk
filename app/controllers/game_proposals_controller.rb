class GameProposalsController < ApplicationController
  add_flash_types :success
  before_action :set_game_proposal, :set_game, only: %i[show destroy]
  before_action :set_groups, only: %i[new]
  before_action :set_game_proposals, only: %i[index]
  skip_after_action :verify_policy_scoped
  # GET /game_proposals
  def index
    @pagy, @game_proposals = pagy(@game_proposals, limit: params[:limit] || GameProposal::PAGE_LIMIT)
    @group = Group.find_by_id(params[:group_id]) if params[:group_id].present?

    respond_to do |format|
      format.html { render :index, locals: {game_proposals: @game_proposals} }
      format.turbo_stream {
        if params[:pending_only]
          render "index_pending", locals: {game_proposals: @game_proposals}
        else
          render "index", locals: {game_proposals: @game_proposals}
        end
      }
    end
  end

  # GET /game_proposals/1 or /game_proposals/1.json
  def show
    respond_to do |format|
      format.html {
        render :show, locals: {
          game_proposal: @game_proposal,
          proposal_availability: @game_proposal.get_user_proposal_availability(Current.user),
          proposal_permission_set: @game_proposal.make_permission_set(@game_proposal.group.users.to_a)
        }
      }
      format.json { render :show, status: :ok, location: @game_proposal }
    end
  end

  # GET /game_proposals/new
  def new
    @game_proposal = if params[:game_id]
      authorize(GameProposal.new(group_id: params[:group_id]))
    else
      authorize(GameProposal.build(group: @groups.first))
    end
    respond_to do |format|
      format.html { render :new, locals: {game_proposal: @game_proposal, groups: @groups} }
    end
  end

  # POST /game_proposals
  def create
    @game_proposal = authorize(GameProposal.new(**game_proposal_params))

    if @game_proposal.save
      redirect_to game_proposal_url(@game_proposal)
    else
      render "create_fail", status: :unprocessable_entity
    end
  end

  # DELETE /game_proposals/1
  def destroy
    authorize(@game_proposal).destroy!

    respond_to do |format|
      format.html {
        redirect_to game_proposals_url, success: {message: I18n.t("game_proposal.destroy.success", name: @game_proposal.game.name),
                                                  options: {highlight: " #{@game_proposal.game.name}"}}
      }
    end
  end

  private

  def set_game_proposal
    @game_proposal = authorize(GameProposal.includes(:proposal_votes).find(params[:id]))
  end

  def set_game
    @game = Game.find_by_id!(@game_proposal.game_id)
  end

  def set_game_proposals
    @game_proposals = if params[:group_id]
      group = Group.find(params[:group_id])
      authorize(group, :show?, policy_class: GroupPolicy)
      GameProposal.includes(:proposal_votes).for_group(params[:group_id])
    else
      policy_scope(GameProposal)
    end
  end

  def set_groups
    @groups = if params[:group_id]
      [Group.find(params[:group_id])]
    else
      Current.user.groups_user_can_create_proposals_for
    end
  end

  # Only allow a list of trusted parameters through.
  def game_proposal_params
    params.require(:game_proposal).permit(:game_id, :yes_votes, :no_votes, :group_id)
  end
end
