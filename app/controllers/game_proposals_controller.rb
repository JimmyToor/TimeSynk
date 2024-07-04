class GameProposalsController < ApplicationController
  before_action :set_game_proposal, only: %i[ show edit update destroy ]

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
  end

  # GET /game_proposals/new
  def new
    @game_proposal = GameProposal.new
  end

  # GET /game_proposals/1/edit
  def edit
  end

  # POST /game_proposals or /game_proposals.json
  def create
    @game_proposal = GameProposal.new(game_proposal_params)

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

    # Only allow a list of trusted parameters through.
    def game_proposal_params
      params.require(:game_proposal).permit(:group_id, :game_checksum, :user_id, :yes_votes, :no_votes)
    end
end
