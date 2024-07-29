class GameProposal < ApplicationRecord
  belongs_to :group
  belongs_to :user
  belongs_to :game
  has_many :proposal_votes, dependent: :destroy, inverse_of: :game_proposal
  has_many :game_sessions, dependent: :destroy
  has_many :proposal_availabilities, dependent: :destroy


  scope :for_current_user_groups, -> { where(group_id: Current.user.groups.ids) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }

  def user_voted?(user)
    proposal_votes.exists?(user_id: user.id)
  end

  def user_voted_yes?(user)
    proposal_votes.exists?(user_id: user.id, yes_vote: true)
  end

  def user_voted_no?(user)
     proposal_votes.exists?(user_id: user.id, yes_vote: false)
  end

  def update_vote_counts!
    update(
      yes_votes_count: proposal_votes.where(yes_vote: true).count,
      no_votes_count: proposal_votes.where(yes_vote: false).count
    )
  end
end
