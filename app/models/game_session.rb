# `duration` is length of time in minutes
class GameSession < ApplicationRecord
  resourcify

  belongs_to :game_proposal
  belongs_to :user, inverse_of: :created_game_sessions
  has_many :game_session_attendances, dependent: :destroy
  has_one :game, through: :game_proposal

  scope :for_current_user_groups, -> { joins(game_proposal: :group).where(groups: { id: Current.user.groups.ids }) }
  scope :for_group, ->(group_id) { joins(game_proposal: :group).where(groups: { id: group_id }) }
  scope :for_game_proposal, ->(game_proposal_id) { where(game_proposal_id: game_proposal_id) }

  validates :duration, presence: true, numericality: { greater_than: 0, allow_nil: true }

  after_save_commit :broadcast_game_session_create
  after_update_commit :broadcast_game_session_update
  after_destroy_commit :broadcast_game_session_destroy

  def user_get_attendance(user)
    game_session_attendances.find_by(user_id: user.id)
  end

  def create_roles
    Role.create_roles_for_game_session(self)
  end

  def get_or_build_attendance_for_user(user)
    attendance = user_get_attendance(user)
    return attendance if attendance
    game_session_attendances.build(user_id: Current.user.id, game_session_id: id)
  end

  def user_attend(user)
    game_session_attendances.create(user: user)
  end

  def user_unattend(user)
    game_session_attendances.find_by(user_id: user.id).destroy
  end

  def game_name
    game_proposal.game.name
  end

  def owner_name
    user.username
  end

  def in_range(icecube_schedule: nil, start_date: nil, end_date: nil)
    return true unless start_date.present? && end_date.present?
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    icecube_schedule.occurs_between?(start_date, end_date)
  end

  def make_icecube_schedule
    # ice_cube treats duration as minutes and game_session duration is already in minutes so no need to convert to seconds
    IceCube::Schedule.new(date, {
      duration: duration
    })
  end

  def make_calendar_schedule(name: nil, icecube_schedule: nil)
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    name = Game.find(game_proposal.game_id).name if name.nil?
    schedule = icecube_schedule.to_hash
    schedule[:id] = id
    schedule[:name] = name
    schedule[:duration] = duration
    schedule[:user_id] = user_id

    schedule
  end

  private

  def broadcast_game_session_update
    user_ids_to_broadcast = game_proposal.group.users.pluck(:id)

    user_ids_to_broadcast.each do |user_id|
      user = User.find(user_id)
      broadcast_replace_later_to(
        "upcoming_game_sessions_user_#{user_id}",
        target: "upcoming_game_sessions",
        partial: "game_sessions/upcoming_game_sessions",
        locals: { upcoming_game_sessions: user.upcoming_game_sessions, user: user }
      )
      broadcast_replace_later_to(
        "game_session_#{id}",
        targets: self,
        partial: "game_sessions/game_session",
        locals: {game_session: self, user: user}
      )
    end
  end

  def broadcast_game_session_create
    user_ids_to_broadcast = game_proposal.group.users.pluck(:id)

    user_ids_to_broadcast.each do |user_id|
      user = User.find(user_id)
      broadcast_replace_later_to(
        "upcoming_game_sessions_user_#{user_id}",
        target: "upcoming_game_sessions",
        partial: "game_sessions/upcoming_game_sessions",
        locals: { upcoming_game_sessions: user.upcoming_game_sessions, user: user }
      )
    end
  end

  def broadcast_game_session_destroy
    user_ids_to_broadcast = game_proposal.group.users.pluck(:id)
    user_ids_to_broadcast.each do |user_id|
      user = User.find(user_id)
      Turbo::Streams::ActionBroadcastJob.perform_later(
        "upcoming_game_sessions_user_#{user_id}",
        action: :replace,
        target: "upcoming_game_sessions",
        partial: "game_sessions/upcoming_game_sessions",
        locals: { upcoming_game_sessions: user.upcoming_game_sessions, user: user }
      )
    end
  end
end
