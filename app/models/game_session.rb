class GameSession < ApplicationRecord
  belongs_to :game_proposal
  belongs_to :user
  has_many :game_session_attendances, dependent: :destroy


  scope :for_current_user_groups, -> { joins(game_proposal: :group).where(groups: { id: Current.user.groups.ids }) }
  scope :for_group, ->(group_id) { joins(game_proposal: :group).where(groups: { id: group_id }) }
  scope :for_game_proposal, ->(game_proposal_id) { where(game_proposal_id: game_proposal_id) }

  def user_get_attendance(user)
    Rails.logger.debug "GameSession#user_set_attendance? id is #{user.id}: #{game_session_attendances.exists?(user_id: user.id)}"
    Rails.logger.debug "GameSession#user_set_attendance?: All attendances #{game_session_attendances.inspect}"
    game_session_attendances.find_by(user_id: user.id)
  end

  def user_get_or_build_attendance(user)
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

  def make_icecube_schedule
    IceCube::Schedule.new(date, {
      duration: duration.minutes
    })
  end

  def make_calendar_schedule(name = nil)
    schedule = make_icecube_schedule
    name = Game.find(game_proposal.game_id).name.to_s if name.nil?

    schedule = schedule.to_hash
    schedule[:id] = id
    schedule[:name] = name
    schedule[:duration] = duration
    schedule[:user_id] = user_id

    Rails.logger.debug "GameSession#make_calendar_data: schedule: #{schedule.inspect}"
    schedule
  end
end
