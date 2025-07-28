class GroupsController < ApplicationController
  add_flash_types :success, :error
  before_action :set_group, only: %i[show edit update destroy]

  # GET /groups
  def index
    @groups = policy_scope(Group)
    @pagy, @groups = pagy(@groups, limit: 10)
    respond_to do |format|
      format.html {
        render :index, locals: {groups: @groups}
      }
    end
  end

  # GET /groups/1
  def show
    @group_membership = GroupMembership.find_by(group: @group, user: Current.user)
    respond_to do |format|
      format.html {
        render :show, locals: {
          group: @group,
          group_membership: @group_membership,
          group_availability: @group.get_user_group_availability(Current.user),
          group_permission_set: @group.make_permission_set(@group.users.to_a)
        }
      }
    end
  end

  # GET /groups/new
  def new
    @group = Group.new
    authorize(@group)
  end

  # GET /groups/1/edit
  def edit
    authorize(@group)
  end

  # POST /groups
  def create
    authorize(Group)
    @group = GroupCreationService.call(group_params, Current.user)
    respond_to do |format|
      if @group.persisted?
        format.turbo_stream {
          redirect_to group_url(@group), success: {message: I18n.t("group.create.success", group_name: @group.name), options: {highlight: @group.name}}
        }
      else
        format.turbo_stream {
          flash.now[:error] = {message: I18n.t("group.create.error"),
                               options: {list_items: @group.errors.full_messages}}
          render partial: "groups/create_fail", status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /groups/1
  def update
    authorize(@group)
    respond_to do |format|
      if @group.update(group_params)
        format.turbo_stream
      else
        format.turbo_stream {
          flash.now[:error] = {message: I18n.t("group.update.error"),
                                options: {list_items: @group.errors.full_messages}}
          render partial: "update_fail", status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /groups/1
  def destroy
    authorize(@group)
    respond_to do |format|
      if @group.destroy
        format.turbo_stream {
          redirect_to groups_path, success: {message: I18n.t("group.destroy.success", group_name: @group.name), id: "groups"}
        }
      else
        format.turbo_stream { render partial: "destroy_fail", status: :unprocessable_entity }
      end
    end
  end

  private

  def set_group
    @group = authorize(Group.find(params[:id]))
  end

  def set_group_membership
    @group_membership = GroupMembership.find_by(group: @group, user: Current.user)
  end

  # Only allow a list of trusted parameters through.
  def group_params
    params.require(:group).permit(:name)
  end
end
