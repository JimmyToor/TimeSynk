class GroupMembershipsController < ApplicationController
  add_flash_types :success, :error
  before_action :set_group_membership, only: %i[show destroy]
  before_action :set_invite, only: %i[create new]
  before_action :set_group, only: %i[index create]
  before_action :set_game_proposal, only: %i[show]
  before_action :set_game_session, only: %i[show]
  before_action :redirect_if_member, only: %i[create]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /group_memberships or /group_memberships.json
  def index
    @group_memberships = params[:query].present? ? @group.group_memberships.search(params[:query]) : @group.group_memberships.sorted_scope
    @pagy, @group_memberships = pagy(@group_memberships, limit: 10)

    respond_to do |format|
      format.html { render :index, locals: {group_memberships: @group_memberships, group: @group} }
      format.turbo_stream
      format.json { render json: @group_memberships }
    end
  end

  # GET /group_memberships/1 or /group_memberships/1.json
  def show
    respond_to do |format|
      format.html {
        render :show, locals: {group_membership: @group_membership}
      }
    end
  end

  # GET /group_memberships/new
  def new
    render :new, locals: {invite: @invite}
  end

  # POST /group_memberships or /group_memberships.json
  def create
    @group_membership = InviteAcceptanceService.call(group_membership_params)

    respond_to do |format|
      if @group_membership.persisted?
        format.html { redirect_to group_path(@group_membership.group), success: {message: I18n.t("group_membership.create.success", group_name: @group_membership.group.name)} }
        format.json { render :show, status: :created, location: @group_membership }
      else
        format.html {
          redirect_to join_group_path, status: :unprocessable_entity,
            error: {message: I18n.t("group_membership.invite_not_valid"),
                    options: {list_items: @group_membership.errors.full_messages}}
        }
        format.json { render json: @group_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_memberships/1 or /group_memberships/1.json
  def destroy
    @group_membership.destroy!

    respond_to do |format|
      if @group_membership.user.id == Current.user.id
        format.html { redirect_to groups_path }
      else
        format.html { redirect_to @group_membership.group, success: {message: I18n.t("group_membership.destroy.success", username: @group_membership.user.username, group_name: @group_membership.group.name)} }
        format.turbo_stream
      end
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
    return unless invite_required?

    token = extract_token(params)
    return if token.blank?

    handle_invite(token)
  end

  def extract_token(params)
    (params[:invite_token] || params.dig(:group_membership, :invite_token))&.sub(%r{.*invite_token=}, "")
  end

  def handle_invite(token)
    @invite = Invite.with_token(token)

    if !@invite.present? || @invite.expired?
      flash[:error] = @invite.nil? ? I18n.t("invite.invalid") : I18n.t("invite.expired")
    end
  end

  def set_group
    @group = params[:group_id] ? Group.find(params[:group_id]) : @invite&.group
    unless @group
      flash[:error] = I18n.t("invite.invalid")
      redirect_to join_group_path(invite_token: @invite&.token) and return
    end
    params[:group_id] = @group.id if params[:group_membership].present? && params[:group_membership][:group_id].blank?
  end

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id]) if params[:game_proposal_id]
  end

  def set_game_session
    @game_session = GameSession.find(params[:game_session_id]) if params[:game_session_id]
  end

  def invite_required?
    params[:invite_token] != "admin" || !Current.user.has_cached_role?(:site_admin)
  end

  def redirect_if_member
    redirect_to @group if @group.is_user_member?(Current.user)
  end
end
