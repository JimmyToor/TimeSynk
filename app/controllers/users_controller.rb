class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit ]

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

  private
  def set_user
    @user = User.find(params[:id])
  end
end
