class UsersController < ApplicationController
  add_flash_types :success, :error
  before_action :set_user, only: %i[update show destroy]
  before_action :set_group, only: %i[show]
  before_action :set_game_proposal, only: %i[show]
  before_action :set_game_session, only: %i[show]
  skip_after_action :verify_authorized, except: %i[update]
  skip_after_action :verify_policy_scoped
  

  def index
  end

  def show
    locals = {user: @user.includes(:roles),
              group: @group,
              group_roles: @group_roles,
              game_proposal: @game_proposal,
              game_session: @game_session}

    respond_to do |format|
      format.html { render :show, locals: locals}
      format.turbo_stream { render :show, locals: locals }
    end
  end
  
  def edit
  end

  def update
    authorize(@user)
    @user.avatar.purge if params.key?(:remove_avatar)
    respond_to do |format|
      if @user.update(user_params)
        flash[:success] = {message: I18n.t("user.avatar.update.success")}
        format.html { redirect_to settings_path, success: {message: I18n.t("user.avatar.update.success")} }
      else
        format.html { redirect_to settings_path, error: {message: I18n.t("user.avatar.update.error"),
                                                          options: {list_items: @user.errors.full_messages}} }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @user.destroy
        format.html { redirect_to root_path, notice: "The account has been deleted." }
      else
        format.html { redirect_to root_path, alert: "There was an error deleting the account." }
      end
    end
  end

  private

  def set_user
    @user = if params[:id].present?
      User.find(params[:id])
    else
      Current.user
    end
  end

  def set_group
    @group = Group.find(params[:group_id]) if params[:group_id].present?
    @group_roles = @user.roles_for_resource(@group) if @group.present?
  end

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id]) if params[:game_proposal_id].present?
    @game_proposal_roles = @user.roles_for_resource(@game_proposal) if @game_proposal.present?
  end

  def set_game_session
    @game_session = GameSession.find(params[:game_session_id]) if params[:game_session_id].present?
    @game_session_roles = @user.roles_for_resource(@game_session) if @game_session.present?
  end

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation, :avatar, :timezone)
  end
end
