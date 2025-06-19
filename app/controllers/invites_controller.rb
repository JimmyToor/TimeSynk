class InvitesController < ApplicationController
  add_flash_types :error, :success
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :set_invite, only: %i[show edit update destroy]
  before_action :set_group, only: %i[show index edit new create]
  before_action :set_roles, only: %i[new edit create]

  # GET /invites or /invites.json
  def index
    @invites = policy_scope(Invite.for_group(params[:group_id]))
    @pagy, @invites = pagy(@invites)
  end

  def show
    # If the user is not a member of the group, render the accept invite page
    render :show, locals: {invite: @invite}
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
        format.html { redirect_to group_invites_path(@group), success: {message: I18n.t("invite.create.success")} }
        format.json { render :show, status: :created, location: @invite }
        format.turbo_stream
      else
        flash.now[:error] = {message: I18n.t("invite.create.error"),
                             options: {list_items: @invite.errors.full_messages}}
        format.html {
          render :new, status: :unprocessable_entity
        }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
        format.turbo_stream { render "create_fail", status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invites/1 or /invites/1.json
  def update
    authorize(@invite)

    respond_to do |format|
      if @invite.update(invite_params)
        format.html { redirect_to invite_path(@invite), success: {message: I18n.t("invite.update.success")} }
        format.json { render :show, status: :ok, location: @invite }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity, error: {message: I18n.t("invite.update.error")} }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
        format.turbo_stream { render "update_fail", status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invites/1 or /invites/1.json
  def destroy
    group = @invite.group
    authorize(@invite)
    @invite.destroy!

    respond_to do |format|
      if !@invite.errors.any?
        format.html { redirect_to group_invites_path(group), success: {message: "Group invite was successfully destroyed."} }
        format.json { head :no_content }
        format.turbo_stream
      else
        format.html { redirect_to group_invites_path(group), error: {message: I18n.t("invite.destroy.error")} }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_invite
    @invite = Invite.with_token(params[:invite_token]) || Invite.find(params[:id])

    unless @invite.present? && @invite.expires_at > Time.current
      error_message = @invite.nil? ? t("invite.invalid") : t("invite.expired")
      @invite ||= Invite.new
      @invite.errors.add(:invite_token, message: error_message)

      render :error, status: :unprocessable_entity and return
    end
    Rails.logger.debug "Invite found: #{@invite.inspect}"
    authorize(@invite)
    Rails.logger.debug "Invite authorized: #{@invite.inspect}"
  end

  def set_group
    Rails.logger.debug "Setting group for invite: params=#{params.inspect}"
    @group = if @invite&.group
      @invite.group
    elsif params.dig(:invite, :group).present?
      Group.find_by(id: params[:invite][:group])
    else
      Group.find_by!(id: params[:group_id])
    end
  end

  def set_roles
    Rails.logger.debug "Setting roles for invite: #{@invite.inspect}, group: #{@group.inspect}"
    @roles = Invite.available_roles(Current.user, @group || @invite.group)
  end

  # Only allow a list of trusted parameters through.
  def invite_params
    params.require(:invite).permit(:user_id, :group_id, :invite_token, :expires_at, assigned_role_ids: [])
  end
end
