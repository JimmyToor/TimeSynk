class PermissionSetsController < ApplicationController
  before_action :set_resource, :set_users, only: %i[edit update]
  before_action :set_role_changes_and_affected_users, only: %i[update], if: -> { params.key?("update_roles") }
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  def edit
    @permission_set = @resource.make_permission_set(@users)
    authorize(@permission_set, policy_class: "#{@resource.class.name}PermissionSetPolicy".constantize)

    render :edit, locals: {permission_set: @permission_set, roles: @resource.roles, title: @title}
  end

  def update
    unless params[:permission_set].blank?
      if params.key?("transfer_ownership")
        transfer_ownership
      else
        update_permissions
      end
    end

    respond_to do |format|
      @permission_set = @resource.make_permission_set(@users)
      @affected_users&.each do |affected_user|
        affected_user.reload.broadcast_role_change_for_resource(@resource)
      end
      format.html { redirect_to @resource, notice: "Permissions were successfully updated." }
      format.turbo_stream
    end
  end

  private

  def permission_set_params
    params.require(:permission_set).permit(:user_id,
      :new_owner_id,
      role_changes: [add_roles: [], remove_roles: []])
  end

  def set_resource
    if params.key?(:group_id)
      @resource = Group.find(params[:group_id])
      @title = @resource.name
    elsif params.key?(:game_proposal_id)
      @resource = GameProposal.find(params[:game_proposal_id])
      @title = @resource.game_name
    else
      raise ActionController::ParameterMissing.new("No resource specified")
    end
  end

  def set_users
    @users = if params[:user_id].present?
      [User.find(params[:user_id])]
    elsif @resource.is_a?(Group)
      @resource.users
    elsif @resource.is_a?(GameProposal)
      @resource.group.users
    elsif @resource.is_a?(GameSession)
      @resource.game_proposal.group.users
    else
      []
    end
  end

  def set_role_changes_and_affected_users
    # Extract role changes from params
    role_changes = permission_set_params[:role_changes].to_h.transform_keys(&:to_i) || {}

    # Get all relevant users and add them to the role changes hash
    users = User.where(id: role_changes.keys).index_by(&:id)

    @role_changes = role_changes.each_with_object({}) do |(user_id, changes), hash|
      hash[user_id] = changes.merge(user: users[user_id])
    end
    @affected_users = users.values
  end

  def update_permissions
    @permission_set = @resource.make_permission_set(@affected_users)
    authorize(@permission_set, policy_class: "#{@resource.class.name}PermissionSetPolicy".constantize)
    @role_changes.each do |user_id, role_changes|
      role_user = role_changes[:user]
      role_user.update_roles(add_roles: role_changes[:add_roles], remove_roles: role_changes[:remove_roles])
    end
  end

  def transfer_ownership
    authorize(@resource, :change_owner?)
    new_owner = User.find(permission_set_params[:new_owner_id])
    TransferOwnershipService.new(new_owner, @resource).transfer_ownership
    @affected_users = [new_owner, Current.user]
  end

  def user_not_authorized(message)
    @message = message
    respond_to do |format|
      format.html { redirect_back_or_to @resource, alert: message }
      format.turbo_stream { render "update_fail_auth", status: :forbidden }
    end
  end

  def handle_parameter_missing(exception)
    render json: {error: exception.message}, status: :unprocessable_entity
  end
end
