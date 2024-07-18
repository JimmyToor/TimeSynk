class ProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :game_proposal

  after_create :increment_vote_count
  after_destroy :decrement_vote_count
  before_update :cache_vote
  after_update :check_vote_change

  private

  attr_accessor :original_vote_value

  def increment_vote_count
    GameProposal.increment_counter(:yes_votes, game_proposal_id) if yes_vote
    GameProposal.increment_counter(:no_votes, game_proposal_id) unless yes_vote
  end

  def decrement_vote_count
    GameProposal.decrement_counter(:yes_votes, game_proposal_id) if yes_vote
    GameProposal.decrement_counter(:no_votes, game_proposal_id) unless yes_vote
  end

  def cache_vote
    @original_vote_value = yes_vote
  end

  # If the vote has changed, decrements the old vote count and increments the new vote count
  def check_vote_change
    if @original_vote_value != yes_vote
      GameProposal.decrement_counter(:no_votes, game_proposal_id) if yes_vote
      GameProposal.decrement_counter(:yes_votes, game_proposal_id) unless yes_vote
      increment_vote_count
    end
  end

end
