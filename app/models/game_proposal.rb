class GameProposal < ApplicationRecord
  belongs_to :group
  belongs_to :user
  belongs_to :game
  has_many :proposal_votes, dependent: :destroy, inverse_of: :game_proposal
  has_many :game_sessions, dependent: :destroy, inverse_of: :game_proposal
  has_many :proposal_availabilities, dependent: :destroy
  
  scope :for_current_user_groups, -> { where(group_id: Current.user.groups.ids) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }

  after_create_commit :broadcast_unvoted_count
  after_destroy_commit :broadcast_unvoted_count

  def user_voted?(user)
    proposal_votes.exists?(user_id: user.id)
  end

  def self.unvoted_count_for_user(user)
    user.groups.includes(:game_proposals).flat_map(&:game_proposals).select { |proposal| !proposal.user_voted?(user) }.count
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
    proposal_votes.build(user_id: Current.user.id)
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

  def create_roles
    Role.create_roles_for_game_proposal(self)
  end

  def broadcast_pending_proposals_change
    user_ids_to_broadcast = group.users.pluck(:id)

    user_ids_to_broadcast.each do |user_id|
      Rails.logger.debug "Broadcasting unvoted count to user #{user_id}"
      broadcast_update_later_to(
        "game_proposals_user_#{user_id}",
        target: "game_proposal_unvoted_count",
        partial: "game_proposals/unvoted_count",
        locals: { user: User.find(user_id) }  # No logged-in context here, so we need to find the user by id
      )
    end
  end

end
