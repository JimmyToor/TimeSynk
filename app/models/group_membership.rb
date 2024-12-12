class GroupMembership < ApplicationRecord
  resourcify

  belongs_to :group
  belongs_to :user


  validates_associated :group, :user
  validates :group, uniqueness: { scope: :user, message: I18n.t("group_membership.already_member") }

  after_destroy :delete_votes, :transfer_resources

  def member_roles
    roles.where(user: user)
  end

  private

  def delete_votes
    user.proposal_votes.where(game_proposal: group.game_proposals).destroy_all
  end

  def transfer_resources
    group.game_proposals.with_role(:owner,user).each do |proposal|
      TransferOwnershipService.new(group.owner, proposal).transfer_ownership
    end
    GameSession.for_group(group.id).with_role(:owner,user).each do |session|
      TransferOwnershipService.new(group.owner, session).transfer_ownership
    end
  end
end
