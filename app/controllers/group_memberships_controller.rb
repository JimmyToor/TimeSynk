class GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[ show edit update destroy ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /group_memberships or /group_memberships.json
  def index
    @group_memberships = GroupMembership.all
  end

  # GET /group_memberships/1 or /group_memberships/1.json
  def show
  end

  # GET /group_memberships/new
  def new
    @group_membership = GroupMembership.build(group_id: params[:group_id])
    @invite = Invite.find_by(invite_token: params[:invite_token])
    group = @invite.group if @invite

    # TODO: Clean this up, role checks should be in the policy
    if Current.user.has_role?(:site_admin)
      group = @group_membership.group
    end

    if !@invite && !group
      render :error, alert: "Invalid invite"
      return
    end

    @group_membership.group_id = params[:group_id]
    @group_membership.user_id = Current.user.id
    render :new, locals: { group_membership: @group_membership, group: group, invite: @invite }
  end

  # GET /group_memberships/1/edit
  def edit

  end

  # POST /group_memberships or /group_memberships.json
  def create # TODO Only let admins create memberships for users that are not themselves
    if group_membership_params[:invite_token].present?
      service = InviteAcceptanceService.new(group_membership_params.merge(group_id: params[:group_id]))
      @group_membership = service.accept_invite
    else
      @group_membership = GroupMembership.new(group_membership_params)
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
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_memberships/1 or /group_memberships/1.json
  def destroy
    @group = @group_membership.group
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
      params.require(:group_membership).permit(:invite_token, :group_id, :user_id)
    end
end
