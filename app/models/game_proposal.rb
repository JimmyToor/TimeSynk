class GameProposal < ApplicationRecord
  belongs_to :group
  belongs_to :user
  belongs_to :game
  has_many :proposal_votes, dependent: :destroy, inverse_of: :game_proposal
  has_many :game_sessions, dependent: :destroy
  has_many :proposal_availabilities, dependent: :destroy


  scope :for_current_user_groups, -> { where(group_id: Current.user.groups.ids) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }

  def user_voted?(user)
    proposal_votes.exists?(user_id: user.id)
  end

  def user_voted_yes?(user)
    proposal_votes.exists?(user_id: user.id, yes_vote: true)
  end

  def user_voted_no?(user)
     proposal_votes.exists?(user_id: user.id, yes_vote: false)
  end

  def update_vote_counts!
    update(
      yes_votes_count: proposal_votes.where(yes_vote: true).count,
      no_votes_count: proposal_votes.where(yes_vote: false).count
    )
  end

  def get_user_proposal_availability(user)
    proposal_availabilities.find_by(user: user)
  end

  def user_get_or_build_vote(user)
    vote = proposal_votes.find_by(user_id: user.id)
    return vote if vote
    proposal_votes.build(user_id: Current.user.id, game_proposal_id: id)
  end

  def make_calendar_schedules(start_date: nil, end_date: nil)
    game_name = Game.find(game_id).name.to_s
    game_sessions.map { |session|
      icecube_schedule = session.make_icecube_schedule
      session.make_calendar_schedule(name: game_name, icecube_schedule:icecube_schedule) if session.in_range(icecube_schedule: icecube_schedule, start_date: start_date, end_date: end_date)
    }.compact
  end

  def game_name
    game.name
  end

end
