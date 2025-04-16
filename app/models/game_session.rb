class GameSession < ApplicationRecord
  resourcify

  require "rounding"

  belongs_to :game_proposal
  has_many :game_session_attendances, dependent: :destroy
  has_one :game, through: :game_proposal

  scope :for_current_user_groups, -> { joins(game_proposal: :group).where(groups: {id: Current.user.groups.ids}) }
  scope :for_group, ->(group_id) { joins(game_proposal: :group).where(groups: {id: group_id}) }
  scope :for_game_proposal, ->(game_proposal_id) { where(game_proposal_id: game_proposal_id) }

  validates :duration, presence: true, numericality: {greater_than: 0, allow_nil: true}
  validate :validate_duration_length

  attr_readonly :game_proposal_id

  after_create :create_roles
  after_save_commit :broadcast_game_session_create
  after_update_commit :broadcast_game_session_update
  after_destroy_commit :broadcast_game_session_destroy

  DEFAULT_PARAMS = {
    date: Time.current.utc.ceil_to(15.minutes),
    duration: 1.hour
  }

  
  def user_get_attendance(user)
    game_session_attendances.find_by(user_id: user.id)
  end

  def create_roles
    Role.create_roles_for_game_session(self)
  end

  def get_or_build_attendance_for_user(user)
    attendance = user_get_attendance(user)
    return attendance if attendance
    game_session_attendances.build(user_id: user.id, game_session_id: id)
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

  def in_range(icecube_schedule: nil, start_time: nil, end_time: nil)
    return true unless start_time.present? && end_time.present?
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    icecube_schedule.occurs_between?(start_time, end_time)
  end

  def make_icecube_schedule
    IceCube::Schedule.new(date, {
      duration: duration
    })
  end

  def make_calendar_schedule(name: nil, icecube_schedule: nil, selectable: true)
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    name = Game.find(game_proposal.game_id).name if name.nil?
    schedule = icecube_schedule.to_hash
    schedule[:id] = id
    schedule[:name] = name
    schedule[:duration] = duration
    schedule[:user_id] = User.with_role(:owner, self).take.id
    schedule[:selectable] = selectable
    schedule
  end

  def self.new_default(game_proposal_id)
    GameSession.new(**DEFAULT_PARAMS, game_proposal_id: game_proposal_id)
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
        locals: {upcoming_game_sessions: user.upcoming_game_sessions.sort_by(&:date), user: user}
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
        locals: {upcoming_game_sessions: user.upcoming_game_sessions.sort_by(&:date), user: user}
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
        locals: {upcoming_game_sessions: user.upcoming_game_sessions.sort_by(&:date), user: user}
      )
    end
  end

  def validate_duration_length
    if !duration.present? || duration.minutes % 15 != 0
      errors.add(:duration, I18n.t("game_session.validation.duration.length"))
    end
  end

  def create_initial_attendance
    game_proposal.group.users.each do |user|
      game_session_attendances.create(user: user, game_session: self)
    end
  end
end
