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

  after_create :create_roles, :create_initial_attendance
  after_create_commit :broadcast_game_session_create
  after_update_commit :broadcast_game_session_update
  after_destroy_commit :broadcast_game_session_destroy
  after_commit :notify_game_session_change

  DEFAULT_PARAMS = {
    date: Time.current.utc.ceil_to(15.minutes),
    duration: 1.hour
  }

  def user_get_attendance(user)
    game_session_attendances.find_by(user_id: user.id)
  end

  def create_roles
    Role.create_roles_for_game_session(self)
    return unless owner.nil?
    Current.user.add_role(:owner, @game_session)
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

  def owner
    @owner ||= User.with_role(:owner, self).first
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
    schedule[:user_id] = User.with_role(:owner, self)&.first&.id
    schedule[:selectable] = selectable
    schedule
  end

  def self.new_default(game_proposal_id)
    GameSession.new(**DEFAULT_PARAMS, game_proposal_id: game_proposal_id)
  end

  def broadcast_game_session_update
    user_ids_to_broadcast = game_proposal.group.users.pluck(:id)

    user_ids_to_broadcast.each do |user_id|
      user = User.find(user_id)
      broadcast_action_later_to(
        "upcoming_game_sessions_user_#{user_id}",
        user_id: user.id,
        action: "frame_reload",
        target: "upcoming_game_sessions_user_#{user.id}",
        render: false
      )
    end

    broadcast_render_later_to(
      "game_session_#{id}",
      template: "game_sessions/update_details",
      locals: {game_session: self}
    )
  end

  def broadcast_game_session_attendances
    broadcast_replace_later_to(
      self,
      targets: "#game_session_#{id}_attendances",
      partial: "game_session_attendances/game_session_attendance_list",
      locals: {game_session: self}
    )
  end

  private

  def broadcast_game_session_create
    user_ids_to_broadcast = game_proposal.group.users.pluck(:id)

    user_ids_to_broadcast.each do |user_id|
      user = User.find(user_id)
      broadcast_action_later_to(
        "upcoming_game_sessions_user_#{user_id}",
        action: "frame_reload",
        target: "upcoming_game_sessions_user_#{user.id}",
        render: false
      )
    end
  end

  def broadcast_game_session_destroy
    user_ids_to_broadcast = game_proposal.group.users.pluck(:id)

    user_ids_to_broadcast.each do |user_id|
      User.find(user_id)

      Turbo::StreamsChannel.broadcast_action_to(
        "upcoming_game_sessions_user_#{user_id}",
        action: "frame_reload",
        target: "upcoming_game_sessions_user_#{user_id}",
        render: false
      )
    end
    broadcast_remove_to(
      "game_session_#{id}",
      target: "game_session_#{id}_attendance_details"
    )

    broadcast_replace_to(
      "game_session_#{id}",
      action: :replace,
      target: "game_session_#{id}_details",
      partial: "game_sessions/destroyed"
    )
  end

  def notify_game_session_change
    return if game_proposal.marked_for_destruction?
    CalendarUpdateNotifierService.call(self)
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
