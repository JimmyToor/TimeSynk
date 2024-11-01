# frozen_string_literal: true

class InviteAcceptanceService
  def initialize(params)
    @params = params
    @invite_token = params[:invite_token]
    @user_id = params[:user_id]
    @group_id = params[:group_id]
  end

  # Creates a new group membership and adds the user's roles.
  #
  # @return [GroupMembership] The newly created group membership.
  def accept_invite
    ActiveRecord::Base.transaction do
      @invite = Invite.find_by(invite_token: @invite_token)
      @group = Group.find_by(id: @group_id)
      user = User.find_by(id: @user_id)

      return invalid_invite unless @group && @invite && user

      @group_membership = new_member(user)
    end
    @group_membership
  rescue ActiveRecord::RecordInvalid => e
    @group_membership ||= GroupMembership.new(user_id: @user_id, group_id: @group_id)
    @group_membership.errors.add(:base, e.message)
    @group_membership
  end

  private

  def invalid_invite
    @group_membership = GroupMembership.new(user_id: @user_id, group_id: @group_id)
    @group_membership.errors.add(:base, I18n.t("group_membership.invite_not_valid"))
    @group_membership
  end

  def new_member(user)
    @group_membership = GroupMembership.create!(user_id: @user_id, group_id: @group_id)
    roles = Role.where(id: @invite.assigned_role_ids).select { |role| role.resource_type == "Group" }
    roles.each do |role|
      user.add_role(role, @group)
    end
    @group_membership
  end

end
