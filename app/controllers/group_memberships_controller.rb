class GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[show edit update destroy]
  before_action :set_invite, only: %i[new create]
  before_action :set_group, only: %i[new create]
  before_action :redirect_if_member, only: %i[new create]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /group_memberships or /group_memberships.json
  def index
    @group_memberships = GroupMembership.all
  end

  # GET /group_memberships/1 or /group_memberships/1.json
  def show
    respond_to do |format|
      format.html { render :show, locals: {group_membership: @group_membership, group_permission_set: @group_membership.group.make_permission_set([@group_membership.user])} }
    end
  end

  # GET /group_memberships/new
  def new
    @group_membership = @group.group_memberships.build

    @group_membership.user_id = Current.user.id
    render :new, locals: {group_membership: @group_membership, group: @group, invite: @invite}
  end

  # GET /group_memberships/1/edit
  def edit
  end

  # POST /group_memberships or /group_memberships.json
  def create # TODO Only let admins create memberships for users that are not themselves
    if group_membership_params[:invite_token].present?
      service = InviteAcceptanceService.new(group_membership_params)
      @group_membership = service.accept_invite
    else
      @group_membership = authorize(GroupMembership.new(group_membership_params))
      @group_membership.save
    end

    respond_to do |format|
      if @group_membership.persisted?
        format.html { redirect_to group_path(@group_membership.group), notice: "You have joined #{@group_membership.group.name}." }
        format.json { render :show, status: :created, location: @group_membership }
      else
        format.html { render :error, status: :unprocessable_entity, notice: @group_membership.errors.full_messages.join(", ") }
        format.json { render json: @group_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /group_memberships/1 or /group_memberships/1.json
  def update
    respond_to do |format|
      if @group_membership.update(group_membership_params)
        format.html { redirect_to group_path(@group_membership.group), notice: "Group membership was successfully updated." }
        format.json { render :show, status: :ok, location: @group_membership }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_memberships/1 or /group_memberships/1.json
  def destroy
    @group_membership.transfer_resources_to_group_owner
    @group_membership.destroy!

    respond_to do |format|
      format.html { redirect_to groups_path, notice: "Group membership was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_group_membership
    @group_membership = GroupMembership.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def group_membership_params
    params.require(:group_membership).permit(:invite_token, :user_id, assigned_role_ids: []).merge(group_id: params[:group_id])
  end

  def set_invite
    @invite = Invite.find_by(invite_token: params[:invite_token] || params.dig(:group_membership, :invite_token))

    return if policy(GroupMembership).create?

    unless @invite && @invite.expires_at > Time.current
      # if no invite is found, let the user know the invite is invalid via adding an error to a new group membership
      error_message = @invite.nil? ? "This invite is invalid" : "This invite has expired"
      @invite ||= Invite.new
      @invite.errors.add(:invite_token, message: error_message)

      render :error, status: :unprocessable_entity
    end
  end

  def set_group
    @group = Group.find(params[:group_id]) if params[:group_id]
    @group = @invite.group unless @group.present?
    unless @group
      @invite.errors.add(:invite_token, message: "This invite is invalid")
      render :error
    end
  end

  def redirect_if_member
    redirect_to @group if @group.is_user_member?(Current.user)
  end
end
