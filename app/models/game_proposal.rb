class GameProposal < ApplicationRecord
  belongs_to :group
  belongs_to :user
  has_many :proposal_votes, dependent: :destroy
  has_many :game_sessions, dependent: :destroy
  has_many :proposal_availabilities, dependent: :destroy
end
