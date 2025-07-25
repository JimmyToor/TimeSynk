class ProposalAvailability < ApplicationRecord
  belongs_to :availability, touch: true
  belongs_to :game_proposal
  belongs_to :user
  has_many :availability_schedules, through: :availability
  has_many :schedules, through: :availability_schedules

  validates :user, uniqueness: {scope: :game_proposal}

  delegate :game_name, to: :game_proposal
  delegate :name, to: :availability, prefix: true
  delegate :username, to: :user

  scope :for_user, ->(user) { where(user: user) }
  scope :for_game_proposal, ->(game_proposal) { where(game_proposal: game_proposal) }
  scope :for_user_and_game_proposal, ->(user, game_proposal) { for_user(user).for_game_proposal(game_proposal) }
end
