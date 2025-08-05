class GameSessionAttendance < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    associated_against: {user: [:username]},
    using: {tsearch: {prefix: true}}

  scope :sorted_scope, -> {
    joins(:user)
      .order(Arel.sql("CASE WHEN attending IS TRUE THEN 0 WHEN attending IS FALSE THEN 1 ELSE 2 END, username ASC"))
  }

  belongs_to :game_session, inverse_of: :game_session_attendances
  belongs_to :user
  has_one :game_proposal, through: :game_session
  has_one :group, through: :game_session

  delegate :name, to: :group, prefix: true
  delegate :game_name, to: :game_proposal

  after_update_commit :broadcast_game_session_attendances

  def group_membership
    GroupMembership.find_by(user_id: user_id, group_id: game_session.group.id)
  end

  def broadcast_game_session_attendances
    return unless game_session_present?
    game_session.broadcast_game_session_attendances
  end

  def game_session_present?
    return false if game_session.nil? || game_session.game_proposal.nil?
    true
  end
end
