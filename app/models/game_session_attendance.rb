class GameSessionAttendance < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    associated_against: {user: [:username]},
    using: {tsearch: {prefix: true}}

  scope :sorted_scope, -> {
    joins(:user)
      .order(Arel.sql("CASE WHEN attending IS TRUE THEN 0 WHEN attending IS FALSE THEN 1 ELSE 2 END, username ASC"))
  }

  belongs_to :game_session
  belongs_to :user

  after_update_commit :broadcast_game_session_attendances

  def broadcast_game_session_attendances
    return unless game_session_present?
    game_session.broadcast_game_session_attendances
  end

  def game_session_present?
    return false if game_session.nil? || game_session.game_proposal.nil?
    true
  end
end
