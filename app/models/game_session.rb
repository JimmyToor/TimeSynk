class GameSession < ApplicationRecord
  belongs_to :game_proposal
  belongs_to :user
  has_many :game_session_attendances, dependent: :destroy
  has_one :game, through: :game_proposal

  scope :for_current_user_groups, -> { joins(game_proposal: :group).where(groups: { id: Current.user.groups.ids }) }
  scope :for_group, ->(group_id) { joins(game_proposal: :group).where(groups: { id: group_id }) }
  scope :for_game_proposal, ->(game_proposal_id) { where(game_proposal_id: game_proposal_id) }

  validates :duration, presence: true, numericality: { greater_than: 0, allow_nil: true }

  def user_get_attendance(user)
    Rails.logger.debug "GameSession#user_set_attendance? id is #{user.id}: #{game_session_attendances.exists?(user_id: user.id)}"
    Rails.logger.debug "GameSession#user_set_attendance?: All attendances #{game_session_attendances.inspect}"
    game_session_attendances.find_by(user_id: user.id)
  end

  def create_roles
    Role.create_roles_for_game_session(self)
  end


  def get_or_build_attendance_for_user(user)
    attendance = user_get_attendance(user)
    return attendance if attendance
    game_session_attendances.build(user_id: Current.user.id, game_session_id: self.id)
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

  def in_range(icecube_schedule: nil, start_date: nil, end_date: nil)
    return true unless start_date.present? && end_date.present?
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    icecube_schedule.occurs_between?(start_date, end_date)
  end

  def make_icecube_schedule
    IceCube::Schedule.new(date, {
      duration: duration.minutes
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
end
