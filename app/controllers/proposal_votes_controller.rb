class ProposalVotesController < ApplicationController
  add_flash_types :error, :success
  before_action :set_proposal_vote, only: %i[show edit update destroy]
  before_action :set_game_proposal, only: %i[new create]
  before_action :set_group_membership, only: %i[show create]
  before_action :check_param_alignment, only: %i[create]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /proposal_votes/1 or /proposal_votes/1.json
  def show
  end

  # GET /proposal_votes/new
  def new
    @proposal_vote = @game_proposal.proposal_votes.build(user_id: Current.user.id, game_proposal_id: @game_proposal.id)
  end

  # GET /proposal_votes/1/edit
  def edit
  end

  # POST /proposal_votes or /proposal_votes.json
  def create
    @proposal_vote = @game_proposal.proposal_votes.build(proposal_vote_params)
    respond_to do |format|
      if @proposal_vote.save
        format.html {
          flash[:success] = {message: I18n.t("proposal_vote.create.success")}
          redirect_to new_game_proposal_proposal_vote_path(@game_proposal)
        }
        format.json { render :show, status: :created, location: @proposal_vote }
        format.turbo_stream
      else
        format.html {
          flash.now[:error] = {message: I18n.t("proposal_vote.create.error"),
                  options: {list_items: @proposal_vote.errors.full_messages}}
          redirect_to new_game_proposal_proposal_vote_path(@game_proposal)
        }
        format.json { render json: @proposal_vote.errors, status: :unprocessable_entity }
        format.turbo_stream {
          flash.now[:error] = {message: I18n.t("proposal_vote.create.error"), options: {list_items: @proposal_vote.errors.full_messages}}
        }
      end
    end
  end

  # PATCH/PUT /proposal_votes/1 or /proposal_votes/1.json
  def update
    respond_to do |format|
      if @proposal_vote.update(proposal_vote_params)
        format.html {
          flash[:success] = {message: I18n.t("proposal_vote.update.success")}
          redirect_to edit_proposal_vote_path(@proposal_vote)
        }
        format.json { render :show, status: :ok, location: @proposal_vote }
        format.turbo_stream
      else
        format.html {
          flash[:error] = {message: I18n.t("proposal_vote.update.error"), options: {list_items: @proposal_vote.errors.full_messages}}
          redirect_to edit_proposal_vote_path(@proposal_vote)
        }
        format.json { render json: @proposal_vote.errors, status: :unprocessable_entity }
        format.turbo_stream {
          flash.now[:error] = {message: I18n.t("proposal_vote.update.error"), options: {list_items: @proposal_vote.errors.full_messages}}
          render "update_fail"
        }
      end
    end
  end

  # DELETE /proposal_votes/1 or /proposal_votes/1.json
  def destroy
    @game_proposal = @proposal_vote.game_proposal
    @proposal_vote.destroy!

    respond_to do |format|
      format.html { redirect_to @game_proposal, notice: "Proposal vote was successfully removed." }
      format.turbo_stream
    end
  end

  private

  def set_game_proposal
    @game_proposal = GameProposal.find_by_id!(params[:game_proposal_id])
  end

  def set_proposal_vote
    @proposal_vote = ProposalVote.find_by_id!(params[:id])
  end

  def proposal_vote_params
    params.require(:proposal_vote).permit(:user_id, :game_proposal_id, :yes_vote, :comment)
  end

  def set_group_membership
    group = if @proposal_vote
      @proposal_vote.game_proposal.group
    else
      @game_proposal.group
    end
    @group_membership = GroupMembership.find_by(user: Current.user, group: group)
  end

  def check_param_alignment
    game_proposal_param = params[:game_proposal_id].to_i
    user_param = params[:proposal_vote][:user_id].to_i
    if game_proposal_param.present? && game_proposal_param != params[:proposal_vote][:game_proposal_id]&.to_i
      render json: {error: "Game Proposal ID did not match the current game proposal."}, status: :unprocessable_entity
    elsif user_param.present? && user_param != Current.user.id
      render json: {error: "User ID did not match the current user."}, status: :unprocessable_entity
    end
  end
end
