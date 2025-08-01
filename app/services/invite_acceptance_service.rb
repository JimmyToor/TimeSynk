# frozen_string_literal: true

# Processes a group invitation acceptance.
# It validates the invite token (unless the user is a site admin),
# finds the associated user and group, and creates a GroupMembership
# within a database transaction. It also assigns roles specified in the invite
# (if any) and creates associated ProposalVotes and GameSessionAttendances
# for existing group proposals/sessions.
#
# @example Accepting an invite
#   params = ActionController::Parameters.new(invite_token: "valid_token", user_id: 1, group_id: 2).permit!
#   @group_membership = InviteAcceptanceService.call(params)
#   if @group_membership.persisted?
#     # Successfully joined the group
#   else
#     # Failed to join, @group_membership contains errors
#   end
class InviteAcceptanceService < ApplicationService
  # Initializes the service with parameters needed to accept the invite.
  #
  # @param params [ActionController::Parameters] Parameters for accepting the invite.
  # @option params [String] :invite_token The unique token from the Invite record.
  # @option params [Integer] :user_id The ID of the User accepting the invite.
  # @option params [Integer] :group_id The ID of the Group being joined.
  def initialize(params)
    @params = params
    @invite_token = params[:invite_token]
    @user_id = params[:user_id]
    @group_id = params[:group_id]
  end

  # Executes the invite acceptance process within a transaction.
  # Validates the invite, user, and group. Creates the GroupMembership,
  # assigns roles via RoleUpdateService, creates related records, and handles errors.
  # Site admins can bypass the invite token requirement.
  #
  # @return [GroupMembership] The new GroupMembership instance.
  def call
    ActiveRecord::Base.transaction do
      @invite = Invite.find_by(invite_token: @invite_token)
      @group = Group.find_by(id: @group_id)
      user = User.find_by(id: @user_id)

      return invalid_invite unless @group && user && @invite
      return expired_invite if @invite&.expired?

      @group_membership = new_member(user)

      @group.game_proposals.each do |game_proposal|
        game_proposal.proposal_votes.create!(game_proposal: game_proposal, user: user)
        game_proposal.game_sessions.each do |game_session|
          game_session.game_session_attendances.create!(game_session: game_session, user: user)
        end
        game_proposal.broadcast_game_proposal_votes
        game_proposal.broadcast_game_proposal_vote_count
      end
    end
    @group_membership
  rescue ActiveRecord::RecordInvalid => e
    @group_membership ||= GroupMembership.new(user_id: @user_id, group_id: @group_id)
    @group_membership.errors.add(:base, e.message)
    @group_membership
  end

  private

  # Creates a GroupMembership instance with an error indicating an invalid invite.
  #
  # @return [GroupMembership] The new, unsaved GroupMembership with errors.
  def invalid_invite
    @group_membership = GroupMembership.new(user_id: @user_id, group_id: @group_id)
    @group_membership.errors.add(:base, I18n.t("invite.invalid"))
    @group_membership
  end

  # Creates a GroupMembership instance with an error indicating an expired invite.
  #
  # @return [GroupMembership] The new, unsaved GroupMembership with errors.
  def expired_invite
    @group_membership = GroupMembership.new(user_id: @user_id, group_id: @group_id)
    @group_membership.errors.add(:base, I18n.t("invite.expired"))
    @group_membership
  end

  # Creates the GroupMembership record and assigns roles based on the invite.
  #
  # @param user [User] The user joining the group.
  # @return [GroupMembership] The newly created and saved GroupMembership instance.
  # @raise [ActiveRecord::RecordInvalid] If the GroupMembership creation fails.
  def new_member(user)
    @group_membership = GroupMembership.create!(user_id: @user_id, group_id: @group_id)
    RoleUpdateService.call(user, @invite.assigned_role_ids || [])
    @group_membership
  end
end
