class ProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :game_proposal

  after_save :update_proposal_vote_counts
  after_destroy :update_proposal_vote_counts

  validates :game_proposal, uniqueness: { scope: :user, message: I18n.t("proposal_vote.vote_unique") }

  after_update do
    update_proposal_vote_counts
  end

  private

  def update_proposal_vote_counts
    game_proposal.update_vote_counts!
  end
end
