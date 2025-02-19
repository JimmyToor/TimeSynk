class InvitesController < ApplicationController
  before_action :set_invite, only: %i[show edit update destroy]
  before_action :set_group, only: %i[index new create]
  before_action :set_roles, only: %i[new edit create]
  before_action :check_param_alignment, only: %i[create]

  # GET /invites or /invites.json
  def index # list invites
    @invites = policy_scope(Invite).for_group(params[:group_id])
  end

  def show
  end

  # GET /groups/1/invite
  def new
    @invite = authorize(@group.invites.build(user_id: Current.user.id))
  end

  # GET /invites/1/edit
  def edit
  end

  # POST /invites or /invites.json
  def create
    @invite = authorize(@group.invites.build(invite_params))

    respond_to do |format|
      if @invite.save
        format.html { redirect_to invite_path(@invite), notice: "Group invite was successfully created" }
        format.json { render :show, status: :created, location: @invite }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invites/1 or /invites/1.json
  def update
    authorize(@invite)
    # Maintain existing assigned roles if user is not allowed to change them
    if Invite.available_roles(Current.user, @invite.group).empty?
      params[:invite][:assigned_role_ids] = @invite.assigned_role_ids
    end

    respond_to do |format|
      if @invite.update(invite_params)
        format.html { redirect_to group_invites_path(@invite.group), notice: "Group invite was successfully updated." }
        format.json { render :show, status: :ok, location: @invite }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invites/1 or /invites/1.json
  def destroy
    group = @invite.group
    authorize(@invite)
    @invite.destroy!

    respond_to do |format|
      format.html { redirect_to group_invites_path(group), notice: "Group invite was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def invite_url(invite)
    accept_invite_url(invite_token: invite.invite_token)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_invite
    @invite = Invite.find(params[:id])
    authorize(@invite)
  end

  def set_group
    @group = Group.find_by!(id: params[:group_id])
  end

  def set_roles
    @group = @invite.group unless @group.present?
    @roles = Invite.available_roles(Current.user, @group)
  end

  # Only allow a list of trusted parameters through.
  def invite_params
    params.require(:invite).permit(:user_id, :group_id, :invite_token, :expires_at, assigned_role_ids: [])
  end

  def check_param_alignment
    group_param = params[:invite][:group_id].to_i
    if group_param.present? && group_param != @group.id
      render json: {error: "Group ID does not match current group."}, status: :unprocessable_entity
    end
  end
end
