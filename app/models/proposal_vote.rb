class ProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :game_proposal, touch: true

  after_save :update_proposal_vote_counts
  after_destroy :update_proposal_vote_counts

  validates :game_proposal, uniqueness: {scope: :user, message: I18n.t("proposal_vote.vote_unique")}, on: :create
  attr_readonly :user_id, :game_proposal_id

  after_commit :broadcast_game_proposal_vote_count

  private

  def update_proposal_vote_counts
    game_proposal.update_vote_counts!
  end

  def broadcast_game_proposal_vote_count
    game_proposal.broadcast_vote_count
  end
end
