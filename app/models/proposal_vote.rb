class ProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :game_proposal

  after_save :update_proposal_vote_counts
  after_destroy :update_proposal_vote_counts

  validates :game_proposal, uniqueness: { scope: :user, message: I18n.t("proposal_vote.vote_unique") }

  after_commit :broadcast_vote_count_later

  private

  def update_proposal_vote_counts
    game_proposal.update_vote_counts!
  end

  def broadcast_vote_count_later
    broadcast_replace_later_to(
      "vote_count_game_proposal_#{game_proposal.id}",
      target: "vote_count_game_proposal_#{game_proposal.id}",
      partial: "game_proposals/vote_count",
      locals: { game_proposal: game_proposal }
    )
  end
end
