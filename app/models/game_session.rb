class GameSession < ApplicationRecord
  belongs_to :game_proposal
  has_many :game_session_attendances, dependent: :destroy
  belongs_to :user
end
