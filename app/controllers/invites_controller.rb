class InvitesController < ApplicationController
  before_action :set_invite, only: %i[ edit update destroy ]

  # GET /invites or /invites.json
  def index # list invites
    @invites = policy_scope(Invite).for_group(params[:group_id])
    @group = Group.find(params[:group_id])
  end

  def show # Let user accept invite, acceptance leads to create group membership
    @invite = Invite.find_by(invite_token: params[:invite_token])
    authorize(@invite)
  end

  # GET /groups/1/invite
  def new
    @invite = Invite.new(group_id: params[:group_id], user_id: Current.user.id)
    authorize(@invite)
  end

  # GET /invites/1/edit
  def edit # Let invite owner (or admin?) edit invite
    authorize(@invite)
  end

  # POST /invites or /invites.json
  def create
    @group = Group.find(invite_params[:group_id])
    @invite = @group.invites.build(invite_params)
    authorize(@invite)

    respond_to do |format|
      if @invite.save
        @invite_url = invite_url(@invite)
        format.html { redirect_to group_invites_url(@group), notice: "Group invite was successfully created: #{@invite_url}" }
        format.json { render :show, status: :created, location: @invite }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invites/1 or /invites/1.json
  def update
    respond_to do |format|
      if @invite.update(invite_params)
        format.html { redirect_to invite_url(@invite), notice: "Group invite was successfully updated." }
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
  end

    # Only allow a list of trusted parameters through.
  def invite_params
    params.require(:invite).permit(:user_id, :group_id, :invite_token, :expires_at, role_ids: [])
  end
end
