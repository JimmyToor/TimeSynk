class GameSession < ApplicationRecord
  belongs_to :game_proposal
  has_many :game_session_attendances, dependent: :destroy
  belongs_to :user

  scope :for_current_user_groups, -> { joins(game_proposal: :group).where(groups: { id: Current.user.groups.ids }) }
  scope :for_group, ->(group_id) { joins(game_proposal: :group).where(groups: { id: group_id }) }
  scope :for_game_proposal, ->(game_proposal_id) { where(game_proposal_id: game_proposal_id) }

  def user_attending?(user)
    game_session_attendances.exists?(user_id: user.id)
  end

  def user_attend(user)
    game_session_attendances.create(user: user)
  end

  def user_unattend(user)
    game_session_attendances.find_by(user_id: user.id).destroy
  end
end
