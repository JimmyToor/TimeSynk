class ProposalVote < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    associated_against: {user: [:username]},
    using: {tsearch: {prefix: true}}

  scope :sorted_scope, -> {
    joins(:user)
      .order(Arel.sql("CASE WHEN yes_vote IS TRUE THEN 0 WHEN yes_vote IS FALSE THEN 1 ELSE 2 END, username ASC"))
  }

  belongs_to :user
  belongs_to :game_proposal

  has_one :group, through: :game_proposal

  delegate :name, to: :group, prefix: true
  delegate :game_name, to: :game_proposal

  after_destroy :update_proposal_vote_counts, unless: :destroyed_via_association?
  after_commit :update_proposal_vote_counts, :broadcast_game_proposal_vote_count, :broadcast_game_proposal_votes, unless: :destroyed_via_association?

  validates :game_proposal, uniqueness: {scope: :user, message: I18n.t("proposal_vote.validation.vote_unique")}, on: :create
  validates :yes_vote, inclusion: {in: [true, false, nil]}, allow_nil: true
  attr_readonly :user_id, :game_proposal_id

  private

  def update_proposal_vote_counts
    return unless game_proposal_present?
    game_proposal.update_vote_counts!
  end

  def broadcast_game_proposal_vote_count
    return unless game_proposal_present?
    game_proposal.broadcast_game_proposal_vote_count
  end

  def broadcast_game_proposal_votes
    return unless game_proposal_present?
    game_proposal.broadcast_game_proposal_votes
  end

  def game_proposal_present?
    return false if game_proposal.nil? || game_proposal.marked_for_destruction?
    true
  end

  def destroyed_via_association?
    destroyed_by_association&.name == :proposal_votes
  end
end
