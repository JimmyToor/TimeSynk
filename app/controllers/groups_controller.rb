class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  # GET /groups or /groups.json
  def index
    @groups = policy_scope(Group)
    authorize @groups
  end

  # GET /groups/1 or /groups/1.json
  def show
    authorize(@group)
    @group_membership = GroupMembership.find_by(group: @group, user: Current.user)
    Rails.logger.debug "availability: #{@group.get_user_group_availability(Current.user)}"

    render :show, locals: { group_availability: @group.get_user_group_availability(Current.user) }
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

  # POST /groups or /groups.json
  def create
    service = GroupCreationService.new(group_params, Current.user)
    @group = service.create_group_and_membership
    authorize(@group)

    respond_to do |format|
      if @group.persisted?
        format.html { redirect_to group_url(@group), notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @group }
      else
        format.html { render :new, status: :unprocessable_entity, notice: I18n.t("group.group_creation_error") }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    authorize(@group)
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to group_url(@group), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit, status: :unprocessable_entity }
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

    # Only allow a list of trusted parameters through.
    def group_params
      params.require(:group).permit(:name, :user_id)
    end
end
