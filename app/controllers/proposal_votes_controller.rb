class ProposalVotesController < ApplicationController
  before_action :set_proposal_vote, only: %i[ show edit update destroy ]
  before_action :set_game_proposal, only: %i[ new create ]
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
    @proposal_vote = @game_proposal.proposal_votes.build(user_id: Current.user.id, game_proposal_id: @game_proposal.id)
  end

  # GET /proposal_votes/1/edit
  def edit
  end

  # POST /proposal_votes or /proposal_votes.json
  def create
    # TODO: Don't allow users to make votes in other users' names i.e. strong params user_id should be the current user's id.
    # TODO: Don't allow users to vote on one proposal from another i.e. game_proposal_id in strong params should match the current proposal's id (from the url params).
    @proposal_vote = @game_proposal.proposal_votes.build(proposal_vote_params)

    respond_to do |format|
      if @proposal_vote.save
        format.html { redirect_to :edit, notice: "Proposal vote was successfully created." }
        format.json { render :show, status: :created, location: @proposal_vote }
        format.turbo_stream
      else
        format.html { render @game_proposal, status: :unprocessable_entity }
        format.json { render json: @proposal_vote.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream:
                  turbo_stream.replace("proposal_vote_form",
                    partial: "proposal_votes/form",
                    method: :morph,
                    locals: { proposal_vote: @proposal_vote,
                              game_proposal: @game_proposal,
                              notice: "Your vote could not be saved" })
        }
      end
    end
  end

  # PATCH/PUT /proposal_votes/1 or /proposal_votes/1.json
  def update
    respond_to do |format|
      if @proposal_vote.update(proposal_vote_params)
        format.html { redirect_to :edit, notice: "Proposal vote was successfully updated." }
        format.json { render :show, status: :ok, location: @proposal_vote }
        format.turbo_stream
      else
        format.html { redirect_to @game_proposal, status: :unprocessable_entity }
        format.json { render json: @proposal_vote.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream:
                   turbo_stream.replace("proposal_vote_form",
                     partial: "proposal_votes/form",
                     method: :morph,
                     locals: { proposal_vote: @proposal_vote,
                               game_proposal: @game_proposal,
                               notice: "Your vote could not be saved" })
        }
      end
    end
  end

  # DELETE /proposal_votes/1 or /proposal_votes/1.json
  def destroy
    @game_proposal = @proposal_vote.game_proposal
    @proposal_vote.destroy!

    respond_to do |format|
      format.html { redirect_to :new, notice: "Proposal vote was successfully removed." }
      format.json { head :no_content }
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
end
