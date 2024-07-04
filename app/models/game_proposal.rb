class GameProposal < ApplicationRecord
  belongs_to :group
  belongs_to :user
  has_many :proposal_votes, dependent: :destroy
  has_many :game_sessions, dependent: :destroy
  has_many :proposal_availabilities, dependent: :destroy

  scope :for_current_user_groups, -> { where(group_id: Current.user.groups.ids) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }

  def user_voted?(user)
    proposal_votes.exists?(user_id: user.id)
  end

  def user_vote(user, vote)
    proposal_votes.create(user: user, vote: vote)
  end

  def user_unvote(user)
    proposal_votes.find_by(user_id: user.id).destroy
  end
end
