class PermissionSetsController < ApplicationController
  before_action :set_resource, only: %i[edit update]
  before_action :set_users, only: %i[edit update]
  before_action :set_user, :set_game_session, :set_game_proposal, :set_group, only: %i[show]
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized, only: %i[show]
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  def show
    respond_to do |format|
      format.html {
        render :show, locals: {user: @user,
                               group: @group,
                               game_proposal: @game_proposal,
                               game_session: @game_session,
                               group_membership: @user.get_membership_for_group(@group)}
      }
    end
  end

  def edit
    @permission_set = @resource.make_permission_set(@users)
    authorize(@permission_set)
    render :edit, locals: {permission_set: @permission_set, roles: @resource.roles.non_special, title: @title}
  end

  def update
    authorize(@resource.make_permission_set(User.where(id: params.dig(:role_changes)&.keys)))
    update_permissions

    respond_to do |format|
      @permission_set = @resource.make_permission_set(@users)
      if @affected_users.present?
        User.where(id: @affected_users.map(&:id)).each do |reloaded_user|
          reloaded_user.broadcast_role_change_for_resource(@resource)
        end
      end
      format.html { redirect_to @resource, success: {message: "Permissions were successfully updated."} }
      format.turbo_stream
    end
  end

  private

  def permission_set_params
    params.require(:permission_set).permit(:user_id, role_changes: [add_roles: [], remove_roles: []])
  end

  def set_resource
    if params.key?(:group_id)
      @resource = Group.find(params[:group_id])
      @title = @resource.name
    elsif params.key?(:game_proposal_id)
      @resource = GameProposal.find(params[:game_proposal_id])
      @title = @resource.game_name
    elsif params.key?(:game_session_id)
      @resource = GameSession.find(params[:game_session_id])
      @title = @resource.game_proposal.game_name
    else
      raise ActionController::ParameterMissing.new("No resource specified")
    end
  end

  def set_users
    @users = if params[:user_id].present?
      [User.find(params[:user_id])]
    elsif @resource.respond_to?(:associated_users)
      @resource.associated_users
    else
      []
    end
  end

  def update_permissions
    @affected_users = PermissionSetUpdateService.call(permission_set_params, Current.user, @resource)
  end

  def user_not_authorized(message)
    notification = {message: t("permission_set.update.authorization_error")}
    respond_to do |format|
      format.html { redirect_back_or_to @resource, error: notification, status: :forbidden }
      format.turbo_stream {
        flash.now[:error] = notification
        render "update_fail_auth", status: :forbidden
      }
    end
  end

  def handle_parameter_missing(exception)
    render json: {error: exception.message}, status: :unprocessable_entity
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_group
    @group = Group.find(params[:group_id]) if params[:group_id]
    @group = @game_proposal.group if @game_proposal.present? && @group.nil?
  end

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id]) if params[:game_proposal_id]
    @game_proposal = @game_session.game_proposal if @game_session.present? && @game_proposal.nil?
  end

  def set_game_session
    @game_session = GameSession.find(params[:game_session_id]) if params[:game_session_id]
  end
end
