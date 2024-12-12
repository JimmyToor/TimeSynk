class UsersController < ApplicationController
  before_action :set_user, only: %i[ update show ]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  def edit
  end

  def show
    if params[:group_id].present?
      @group = Group.find(params[:group_id])
      @group_roles = @user.roles_for_resource(@group) if @group.is_user_member?(@user)

      if params[:game_proposal_id].present?
        @game_proposal = GameProposal.find(params[:game_proposal_id])
        @game_proposal_roles = @user.roles_for_resource(@game_proposal) if @game_proposal.present?
      end

      if params[:game_session_id].present?
        @game_session = GameSession.find(params[:game_session_id])
        @game_session_roles = @user.roles_for_resource(@game_session) if @game_session.present?
      end
    end
    respond_to do |format|
      format.html { render :show, locals: {user: @user,
                                           group: @group,
                                           group_roles: @group_roles,
                                           game_proposal: @game_proposal,
                                           game_proposal_roles: @game_proposal_roles,
                                           game_session: @game_session,
                                           game_session_roles: @game_session_roles} }
      format.turbo_stream
    end
  end

  def update
    @user.avatar.purge if user_params[:avatar] === ""

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to settings_path, notice: "Your settings were updated successfully"}
        format.turbo_stream
      else
        render :edit, status: :unprocessable_entity
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

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation, :avatar, :timezone)
  end
end
