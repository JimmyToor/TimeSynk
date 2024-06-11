class ProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :game_proposal
end
