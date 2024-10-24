class UsersController < ApplicationController
  before_action :set_user, only: %i[ update show ]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  def edit
  end

  def show
    if params[:group_id].present?
      @group = Group.find(params[:group_id])
      @roles = @user.roles.where(resource: @group) if @group.users.include?(@user)
    end
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    @user.avatar.purge if user_params[:avatar] === ""

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to settings_path, notice: "Your settings were updated successfully"}
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@user, partial: "users/user", locals: { user: @user }) }
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
