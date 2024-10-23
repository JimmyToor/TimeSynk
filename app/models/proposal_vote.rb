class ProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :game_proposal

  after_save :update_proposal_vote_counts
  after_destroy :update_proposal_vote_counts

  after_commit :broadcast_unvoted_count

  validates :game_proposal, uniqueness: { scope: :user, message: I18n.t("proposal_vote.vote_unique") }


  private

  def broadcast_unvoted_count
    game_proposal.broadcast_unvoted_count
  end

  def update_proposal_vote_counts
    game_proposal.update_vote_counts!
  end
end
