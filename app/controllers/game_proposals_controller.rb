class GameProposalsController < ApplicationController
  before_action :set_game_proposal, :set_game, only: %i[ show edit update destroy ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  require "igdb_client"

  # GET /game_proposals or /game_proposals.json
  def index
    @game_proposals = if params[:group_id]
      GameProposal.for_group(params[:group_id])
    else
      GameProposal.for_current_user_groups
    end
  end

  # GET /game_proposals/1 or /game_proposals/1.json
  def show
    @proposal_vote = if @game_proposal.user_voted?(@game_proposal)
      Current.user.get_vote_for_proposal(@game_proposal)
    else
      ProposalVote.new(user_id: Current.user.id, game_proposal_id: @game_proposal.id)
    end

    render locals: {
      voted: @game_proposal.user_voted?(@game_proposal),
      voted_yes: @game_proposal.user_voted_yes?(@game_proposal),
      voted_no: @game_proposal.user_voted_no?(@game_proposal)
    }
  end

  # GET /game_proposals/new
  def new
    @game_proposal = GameProposal.new(group_id: params[:group_id])
  end

  # GET /game_proposals/1/edit
  def edit
    @game = Game.find_by(id: @game_proposal.game_id)
  end

  # POST /game_proposals or /game_proposals.json
  def create
    @game_proposal = GameProposal.new(game_proposal_params.merge(group_id: params[:group_id]))

    respond_to do |format|
      if @game_proposal.save
        format.html { redirect_to game_proposal_url(@game_proposal), notice: "Game proposal was successfully created." }
        format.json { render :show, status: :created, location: @game_proposal }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game_proposal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /game_proposals/1 or /game_proposals/1.json
  def update
    Rails.logger.debug "GameProposal Update params: #{game_proposal_params}"
    respond_to do |format|
      if @game_proposal.update(game_proposal_params)
        format.html { redirect_to game_proposal_url(@game_proposal), notice: "Game proposal was successfully updated." }
        format.json { render :show, status: :ok, location: @game_proposal }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_proposal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /game_proposals/1 or /game_proposals/1.json
  def destroy
    @game_proposal.destroy!

    respond_to do |format|
      format.html { redirect_to game_proposals_url, notice: "Game proposal was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_proposal
      @game_proposal = GameProposal.find(params[:id])
    end

    def set_game
      @game = Game.find_by_id!(@game_proposal.game_id)
    end

    # Only allow a list of trusted parameters through.
    def game_proposal_params
      params.require(:game_proposal).permit(:game_id, :user_id, :yes_votes, :no_votes, :group_id)
    end


end
