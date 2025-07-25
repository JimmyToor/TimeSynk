class GameSession < ApplicationRecord
  include Restrictable

  resourcify
  restrict(min_weight: RoleHierarchy::ROLE_WEIGHTS[:"game_session.owner"])

  require "rounding"

  belongs_to :game_proposal
  has_many :game_session_attendances, dependent: :destroy
  has_one :group, through: :game_proposal
  has_one :game, through: :game_proposal

  scope :for_current_user_groups, -> { joins(game_proposal: :group).where(groups: {id: Current.user.groups.ids}) }
  scope :for_group, ->(group_id) { joins(game_proposal: :group).where(groups: {id: group_id}) }
  scope :for_game_proposal, ->(game_proposal_id) { where(game_proposal_id: game_proposal_id) }
  scope :upcoming, -> { where("date >= ?", Time.current.utc) }

  validates :duration, presence: true, numericality: {greater_than: 0}
  validate :validate_duration_length
  validates_datetime :date, presence: true, timeliness: {type: :datetime}

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

  PAGE_LIMIT = 8
  PAGE_LIMIT_SHORT = 5

  def self.role_providing_associations
    [:game_proposal]
  end

  def reload(options = nil)
    @owner = nil
    super
  end

  def associated_users
    group.associated_users
  end

  def associated_users_without_owner
    group.associated_users_without_owner
  end

  def owner
    @owner ||= User.with_role(:owner, self).first
  end

  def user_get_attendance(user)
    game_session_attendances.find_by(user_id: user.id)
  end

  def create_roles
    Role.create_roles_for_game_session(self)
    return unless owner.nil?
    Current.user.add_role(:owner, self)
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
    game_session_attendances.find_by(user_id: user.id)&.destroy
  end

  def game_name
    game_proposal.game.name
  end

  def group_name
    game_proposal.group.name
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

  # Generates a calendar schedule hash for the game session.
  # Fields:
  # - id: Unique identifier for the game session
  # - name: Name of the game session (displayed in the calendar)
  # - duration: Duration of the game session as an interval
  # - user_id: ID of the user who owns the game session
  # - selectable: Boolean indicating if the schedule is selectable
  # - group: Name of the group associated with the game proposal
  # - icecube_schedule fields: start_time, end_time, rrules, rtimes, extimes
  #
  # @param name [String, nil] The name of the game session.
  # @param icecube_schedule [IceCube::Schedule, nil] The IceCube schedule object.
  # @param selectable [Boolean] Indicates if the schedule is selectable.
  # @return [Hash] A hash representing the calendar schedule.
  def make_calendar_schedule(name: nil, icecube_schedule: nil, selectable: true)
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    name = Game.find(game_proposal.game_id).name if name.nil?
    schedule = icecube_schedule.to_hash

    schedule[:id] = id
    schedule[:name] = name
    schedule[:duration] = duration
    schedule[:selectable] = selectable
    schedule[:group] = game_proposal.group.name

    schedule
  end

  def self.new_default(game_proposal_id)
    GameSession.new(**DEFAULT_PARAMS, game_proposal_id: game_proposal_id)
  end

  def broadcast_game_session_update
    return unless saved_change_to_date? || saved_change_to_duration?

    if saved_change_to_date?
      UpcomingGameSessionUpdatesChannel.broadcast_to(
        group,
        old_date: saved_change_to_date&.first,
        new_date: date
      )
    end

    broadcast_render_later(
      template: "game_sessions/update_details",
      locals: {game_session: self}
    )
  end

  def broadcast_game_session_attendances
    broadcast_replace_later(
      targets: ".game_session_#{id}_attendances",
      partial: "game_session_attendances/game_session_attendance_list",
      locals: {game_session: self}
    )
  end

  private

  def broadcast_game_session_create
    UpcomingGameSessionUpdatesChannel.broadcast_to(
      group,
      old_date: nil,
      new_date: date
    )
  end

  def broadcast_game_session_destroy
    return if game_proposal.marked_for_destruction?

    UpcomingGameSessionUpdatesChannel.broadcast_to(
      group,
      old_date: date,
      new_date: date
    )

    broadcast_replace_to(
      self,
      action: :replace,
      targets: ".content_game_session_#{id}",
      partial: "game_sessions/destroyed"
    )
  end

  def notify_game_session_change
    return if game_proposal.marked_for_destruction?
    CalendarUpdateNotifierService.call(self)
  end

  def validate_duration_length
    return unless duration.present? && duration.is_a?(Numeric)
    if duration.minutes % 15 != 0
      errors.add(:duration, I18n.t("game_session.validation.duration.length"))
    end
  end

  def create_initial_attendance
    game_proposal.group.users.each do |user|
      game_session_attendances.create(user: user, game_session: self)
    end
  end
end
