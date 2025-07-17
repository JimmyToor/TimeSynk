class InvitesController < ApplicationController
  add_flash_types :error, :success
  before_action :set_invite, only: %i[show edit update destroy]
  before_action :set_group, only: %i[show index edit new create]
  before_action :set_roles, only: %i[new edit create]

  # GET /invites
  def index
    @invites = policy_scope(Invite.for_group(params[:group_id]))
    @pagy, @invites = pagy(@invites)
  end

  # GET /invites/1
  def show
    render :show, locals: {invite: @invite}
  end

  # GET /groups/1/invite
  def new
    @invite = authorize(@group.invites.build(user_id: Current.user.id))
  end

  # GET /invites/1/edit
  def edit
  end

  # POST /invites
  def create
    @invite = authorize(@group.invites.build(invite_params))

    respond_to do |format|
      if @invite.save
        format.html { redirect_to group_invites_path(@group), success: {message: I18n.t("invite.create.success")} }
        format.turbo_stream
      else
        flash.now[:error] = {message: I18n.t("invite.create.error"),
                             options: {list_items: @invite.errors.full_messages}}
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render "create_fail", status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invites/1
  def update
    authorize(@invite)
    respond_to do |format|
      if @invite.update(invite_params)
        format.html { redirect_to invite_path(@invite), success: {message: I18n.t("invite.update.success")} }
        format.turbo_stream
      else
        set_roles
        flash.now[:error] = {message: I18n.t("invite.update.error"), options: {list_items: @invite.errors.full_messages}}
        format.html { render :edit, status: :unprocessable_entity, error: {message: I18n.t("invite.update.error")} }
        format.turbo_stream { render "update_fail", status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invites/1
  def destroy
    authorize(@invite)

    respond_to do |format|
      if @invite.destroy
        format.turbo_stream
      else
        format.turbo_stream { turbo_stream_toast(:error, t("invite.destroy.error"), "invite_#{@invite.id}") }
      end
    end
  end

  private

  def set_invite
    @invite = Invite.with_token(params[:invite_token]) || Invite.find(params[:id])
    authorize(@invite)
  end

  def set_group
    @group = if @invite&.group
      @invite.group
    elsif params.dig(:invite, :group).present?
      Group.find_by(id: params[:invite][:group])
    else
      Group.find_by!(id: params[:group_id])
    end
  end

  def set_roles
    @roles = Invite.available_roles(Current.user, @group || @invite.group)
  end

  # Only allow a list of trusted parameters through.
  def invite_params
    params.require(:invite).permit(:user_id, :group_id, :invite_token, :expires_at, assigned_role_ids: [])
  end
end
