class GroupMembership < ApplicationRecord
  resourcify

  include PgSearch::Model
  pg_search_scope :search,
    associated_against: {user: [:username]},
    using: {tsearch: {prefix: true}}

  scope :sorted_scope, -> {
    joins(:user)
      .order("username")
  }

  belongs_to :group
  belongs_to :user

  validates_associated :group, :user
  validates :group, uniqueness: {scope: :user, message: I18n.t("group_membership.already_member")}

  before_destroy :transfer_resources_to_group_owner, unless: :destroyed_via_association?
  after_destroy :delete_votes

  def member_roles
    roles.where(user: user)
  end

  def transfer_resources_to_group_owner
    unless user.has_cached_role?(:owner, group)
      group.game_proposals.with_role(:owner, user).each do |proposal|
        TransferOwnershipService.call(group.owner, proposal)
      end
      GameSession.for_group(group.id).with_role(:owner, user).each do |session|
        TransferOwnershipService.call(group.owner, session)
      end
    end
  end

  private

  def delete_votes
    user.proposal_votes.where(game_proposal: group.game_proposals).destroy_all
  end

  def destroyed_via_association?
    destroyed_by_association&.name == :group_memberships
  end
end
