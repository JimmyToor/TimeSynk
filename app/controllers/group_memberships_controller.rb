class GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[show edit update destroy]
  before_action :set_invite, only: %i[create]
  before_action :set_group, only: %i[create]
  before_action :redirect_if_member, only: %i[create]
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
  end

  # GET /group_memberships/1/edit
  def edit
  end

  # POST /group_memberships or /group_memberships.json
  def create
    if group_membership_params[:invite_token].present?
      service = InviteAcceptanceService.new(group_membership_params)
      @group_membership = service.accept_invite
    else
      @group_membership = GroupMembership.new(group_membership_params)
      @group_membership.errors.add(:base, I18n.t("group_membership.invite_not_valid"))
    end

    respond_to do |format|
      if @group_membership.persisted?
        format.html { redirect_to group_path(@group_membership.group), notice: "You have joined #{@group_membership.group.name}." }
        format.json { render :show, status: :created, location: @group_membership }
      else
        format.html { redirect_to join_group_with_token_path, status: :unprocessable_entity, notice: @group_membership.errors.full_messages.join(", ") }
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
      format.html { redirect_to groups_path, notice: "You've left the group." }
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
    return if Current.user.has_cached_role?(:site_admin)
    @invite = Invite.with_token(params[:invite_token] || group_membership_params[:invite_token])
    flash[:invite_token] = params[:invite_token] || group_membership_params[:invite_token]

    unless @invite.present? && @invite.expires_at > Time.current
      flash[:alert] = @invite.nil? ? "This invite is invalid" : "This invite has expired"
      redirect_to join_group_with_token_path and return
    end
    params[:group_membership][:assigned_role_ids] = @invite.assigned_role_ids if params[:group_membership][:assigned_role_ids].blank?
  end

  def set_group
    @group = Group.find(params[:group_id]) if params[:group_id]
    @group = @invite&.group unless @group.present?
    unless @group
      flash[:alert] = "This invite is invalid"
      redirect_to join_group_with_token_path and return
    end
    params[:group_id] = @group.id if params[:group_membership][:group_id].blank?
  end

  def redirect_if_member
    redirect_to @group if @group.is_user_member?(Current.user)
  end
end
