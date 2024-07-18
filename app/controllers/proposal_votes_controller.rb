class ProposalVotesController < ApplicationController
  before_action :set_proposal_vote, only: %i[ show edit update destroy ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /proposal_votes or /proposal_votes.json
  def index
    @proposal_votes = ProposalVote.all
  end

  # GET /proposal_votes/1 or /proposal_votes/1.json
  def show
  end

  # GET /proposal_votes/new
  def new
    @proposal_vote = ProposalVote.new
  end

  # GET /proposal_votes/1/edit
  def edit
  end

  # POST /proposal_votes or /proposal_votes.json
  def create
    @proposal_vote = ProposalVote.new(proposal_vote_params)

    if ProposalVote.find_by(user_id: @proposal_vote.user_id, game_proposal_id: @proposal_vote.game_proposal_id)
      @proposal_vote.errors.add(:base, "You have already voted on this proposal")
      return render :new, status: :unprocessable_entity
    end

    respond_to do |format|
      if @proposal_vote.save
        format.html { redirect_to proposal_vote_url(@proposal_vote), notice: "Proposal vote was successfully created." }
        format.json { render :show, status: :created, location: @proposal_vote }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @proposal_vote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /proposal_votes/1 or /proposal_votes/1.json
  def update
    respond_to do |format|
      if @proposal_vote.update(proposal_vote_params)
        format.html { redirect_to proposal_vote_url(@proposal_vote), notice: "Proposal vote was successfully updated." }
        format.json { render :show, status: :ok, location: @proposal_vote }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @proposal_vote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /proposal_votes/1 or /proposal_votes/1.json
  def destroy
    @proposal_vote.destroy!

    respond_to do |format|
      format.html { redirect_to proposal_votes_url, notice: "Proposal vote was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_proposal_vote
      @proposal_vote = ProposalVote.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def proposal_vote_params
      params.require(:proposal_vote).permit(:user_id, :game_proposal_id, :yes_vote, :comment).merge(game_proposal_id: params[:game_proposal_id])
    end
end
