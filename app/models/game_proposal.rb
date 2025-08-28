class GameProposal < ApplicationRecord
  include Restrictable
  resourcify
  restrict(min_weight: RoleHierarchy::ROLE_WEIGHTS[:"game_proposal.admin"])

  include PgSearch::Model
  pg_search_scope :search,
    associated_against: {user: [:username]},
    using: {tsearch: {prefix: true}}

  belongs_to :group
  belongs_to :game
  has_many :proposal_votes, dependent: :destroy, inverse_of: :game_proposal
  has_many :game_sessions, dependent: :destroy, inverse_of: :game_proposal
  has_many :proposal_availabilities, dependent: :destroy

  scope :for_current_user_groups, -> { where(group_id: Current.user.groups.ids) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }

  after_create_commit :broadcast_pending_game_proposal_changes
  after_destroy_commit :broadcast_game_proposal_destroyed

  after_create :create_initial_votes, :create_roles

  validates :game, uniqueness: {scope: :group, message: "already has a proposal in this group"}

  delegate :name, to: :game, prefix: true
  delegate :name, to: :group, prefix: true

  PAGE_LIMIT = 8
  PAGE_LIMIT_SHORT = 5

  def self.role_providing_associations
    [:group]
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

  def get_upcoming_game_sessions(date_limit: nil)
    if date_limit.nil?
      game_sessions.where("date >= ?", Time.current)
    else
      game_sessions.where("date >= ? AND date <= ?", Time.current, date_limit)
    end
  end

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

  def user_get_or_build_vote(user, yes_vote: nil)
    vote = proposal_votes.find_by(user_id: user.id)
    return vote if vote
    proposal_votes.build(user_id: user.id, yes_vote: yes_vote)
  end

  def make_calendar_schedules(start_time: nil, end_time: nil)
    game_name = Game.find(game_id).name.to_s
    sessions = sessions_in_range(start_time: start_time, end_time: end_time)
    sessions.map { |session|
      session.make_calendar_schedule(name: game_name)
    }.compact
  end

  # Retrieves game sessions that fall within a specified time range.
  #
  # @param start_time [Time, nil] The start of the time range. If nil, only the end_time is considered.
  # @param end_time [Time, nil] The end of the time range. If nil, only the start_time is considered.
  # @return [ActiveRecord::Relation] A collection of game sessions that match the specified time range.
  def sessions_in_range(start_time: nil, end_time: nil)
    if start_time.present? && end_time.nil?
      # If only start_time is provided, return sessions that end after or on the given start_time.
      game_sessions.where("date + duration >= ?", start_time)
    elsif end_time.present? && start_time.nil?
      # If only end_time is provided, return sessions that start before or on the given end_time.
      game_sessions.where("date <= ?", end_time)
    else
      # If both start_time and end_time are provided, return sessions that:
      # - Start or end within the range.
      # - Span across the entire range.
      game_sessions.where("(date >= ? AND date <= ?) OR (date + duration >= ? AND date + duration <= ?) OR (date < ? AND date + duration > ?)",
        start_time, end_time, start_time, end_time, start_time, end_time)
    end
  end

  def broadcast_game_proposal_destroyed
    broadcast_pending_game_proposal_changes
    broadcast_game_proposal_removal
    CalendarUpdateNotifierService.call(group)
  end

  def broadcast_pending_game_proposal_changes
    # only need to notify users with no vote for this proposal
    relevant_users = group.users.joins("LEFT JOIN proposal_votes ON proposal_votes.user_id = users.id AND proposal_votes.game_proposal_id = #{id}")
    counts = relevant_users.map { |user| [user.id, user.pending_game_proposal_count] }.to_h

    counts.each do |user_id, count|
      broadcast_pending_game_proposal_updates_for_user(user_id, count: count)
    end
  end

  # Broadcasts updates to the pending game proposal count for a specific user.
  def broadcast_pending_game_proposal_updates_for_user(user_id, count: nil)
    count ||= User.find(user_id).pending_game_proposal_count

    GameProposals::UpdatePendingCountBroadcastJob.perform_later(user_id, count: count)
    broadcast_pending_game_proposal_reload(user_id)
  end

  def broadcast_game_proposal_removal
    associated_users.each do |user|
      Turbo::Streams::ActionBroadcastJob.perform_later(
        "game_proposals_user_#{user.id}",
        action: :remove,
        target: "game_proposal_#{id}"
      )
    end
  end

  def broadcast_pending_game_proposal_reload(user_id)
    Turbo::Streams::ActionBroadcastJob.perform_later(
      "pending_game_proposals_user_#{user_id}",
      action: "frame_reload",
      target: "pending_game_proposals",
      render: false
    )
  end

  def broadcast_game_proposal_vote_count
    broadcast_replace_later_to(
      self,
      targets: "#vote_count_game_proposal_#{id}",
      partial: "game_proposals/vote_count"
    )
  end

  def broadcast_game_proposal_votes
    broadcast_replace_later_to(
      self,
      targets: "#game_proposal_#{id}_votes",
      partial: "proposal_votes/proposal_vote_list"
    )
  end

  def notify_calendar_update(cascade = true)
    CalendarUpdateNotifierService.call(self, cascade)
  end

  private

  def create_initial_votes
    now = Time.current
    initial_votes = group.users.map do |user|
      {
        user_id: user.id,
        game_proposal_id: id,
        created_at: now,
        updated_at: now
      }
    end

    ProposalVote.insert_all(initial_votes)
    update_vote_counts!
    broadcast_game_proposal_vote_count
    broadcast_game_proposal_votes
  end

  def create_roles
    Role.create_roles_for_game_proposal(self)
    return unless owner.nil?
    Current.user.add_role(:owner, self)
  end
end
