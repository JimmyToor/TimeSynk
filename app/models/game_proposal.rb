class GameProposal < ApplicationRecord
  resourcify

  belongs_to :group
  belongs_to :user, inverse_of: :created_game_proposals
  belongs_to :game
  has_many :proposal_votes, dependent: :destroy, inverse_of: :game_proposal
  has_many :game_sessions, dependent: :destroy, inverse_of: :game_proposal
  has_many :proposal_availabilities, dependent: :destroy
  
  scope :for_current_user_groups, -> { where(group_id: Current.user.groups.ids) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }

  after_create_commit :broadcast_user_game_proposals_change
  after_destroy_commit :broadcast_user_game_proposals_destroy

  after_create :create_initial_votes, :create_roles

  validates :game, uniqueness: { scope: :group, message: "already has a proposal for this group" }

  def yes_votes
    proposal_votes.where(yes_vote: true)
  end

  def no_votes
    proposal_votes.where(yes_vote: false)
  end

  def undecided_votes
    proposal_votes.where(yes_vote: nil).or(proposal_votes.where(user_id: group.users.where.not(id: proposal_votes.select(:user_id)).select(:id)))
  end

  def user_voted?(user)
    proposal_votes.exists?(user_id: user.id)
  end

  def user_voted_yes_or_no?(user)
    proposal_votes.exists?(user_id: user.id, yes_vote: [true, false])
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

  def broadcast_user_game_proposals_change
    user_ids_to_broadcast = group.users.pluck(:id)
    users_to_broadcast = User.where(id: user_ids_to_broadcast).includes(:game_proposals)
    users_to_broadcast.each do |user|
      broadcast_update_later_to(
        "pending_game_proposals_count_user_#{user.id}",
        target: "pending_game_proposals_count",
        partial: "game_proposals/pending_count",
        locals: {count: user.pending_game_proposal_count}
      )
      broadcast_replace_later_to(
        "pending_game_proposals_user_#{user.id}",
        target: "pending_game_proposals",
        partial: "game_proposals/pending_game_proposals",
        locals: {pending_game_proposals: user.pending_game_proposals}
      )
      broadcast_update_later_to(
        "game_proposals_user_#{user.id}",
        target: "game_proposals",
        partial: "game_proposals/game_proposals_list",
        locals: {game_proposals: user.game_proposals.to_ary}
      )
    end
  end

  def broadcast_user_game_proposals_destroy
    user_ids_to_broadcast = group.users.pluck(:id)
    users_to_broadcast = User.where(id: user_ids_to_broadcast).includes(:game_proposals)
    users_to_broadcast.each do |user|
      Turbo::Streams::ActionBroadcastJob.perform_later(
        "pending_game_proposals_count_user_#{user.id}",
        action: :update,
        target: "pending_game_proposals_count",
        partial: "game_proposals/pending_count",
        locals: {count: user.pending_game_proposal_count}
      )
      Turbo::Streams::ActionBroadcastJob.perform_later(
        "pending_game_proposals_user_#{user.id}",
        action: :replace,
        target: "pending_game_proposals",
        partial: "game_proposals/pending_game_proposals",
        locals: {pending_game_proposals: user.pending_game_proposals}
      )
      Turbo::Streams::ActionBroadcastJob.perform_later(
        "game_proposals_user_#{user.id}",
        action: :replace,
        target: "game_proposals",
        partial: "game_proposals/game_proposals_list",
        locals: {game_proposals: user.game_proposals.to_ary}
      )
    end
  end

  def broadcast_vote_count
    id = "vote_count_game_proposal_#{self.id}"
    broadcast_replace_later_to(self,
      target: id,
      partial: "game_proposals/vote_count",
      locals: {game_proposal: self}
    )
  end

  private

  def create_initial_votes
    group.users.each do |user|
      proposal_votes.create(user: user)
    end
  end

  def create_roles
    Role.create_roles_for_game_proposal(self)
  end

  def broadcast_later
    broadcast_refresh_later_to(self, target: self, partial: "game_proposals/game_proposal", locals: {game_proposal: self})
  end

end
