class ProposalAvailability < ApplicationRecord
  belongs_to :schedule, dependent: :destroy
  belongs_to :user
  belongs_to :game_proposal
end
