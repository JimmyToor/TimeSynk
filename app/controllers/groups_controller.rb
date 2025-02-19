class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy]
  before_action :set_group_membership, only: %i[update]

  # GET /groups or /groups.json
  def index
    @groups = policy_scope(Group)
    @group_memberships = Current.user.group_memberships
    authorize @groups
  end

  # GET /groups/1 or /groups/1.json
  def show
    authorize(@group)
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

    respond_to do |format|
      format.html
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("modal_frame",
          partial: "groups/edit")
      }
    end
  end

  # POST /groups or /groups.json
  def create
    service = GroupCreationService.new(group_params, Current.user)
    @group = service.create_group_and_membership
    authorize(@group)
    @group_permission_set = @group.make_permission_set(@group.users.to_a)

    respond_to do |format|
      if @group.persisted?
        format.html { redirect_to group_url(@group), notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @group }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity, notice: I18n.t("group.group_creation_error") }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    authorize(@group)
    original_name = @group.name
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to group_url(@group), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @group }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity, locals: {group: @group, original_name: original_name} }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1 or /groups/1.json
  def destroy
    authorize(@group)
    @group.destroy!

    respond_to do |format|
      format.html { redirect_to groups_url, notice: "Group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find(params[:id])
  end

  def set_group_membership
    @group_membership = GroupMembership.find_by(group: @group, user: Current.user)
  end

  # Only allow a list of trusted parameters through.
  def group_params
    params.require(:group).permit(:name)
  end
end
