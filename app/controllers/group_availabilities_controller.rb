class GroupAvailabilitiesController < ApplicationController
  add_flash_types :success
  before_action :set_group_availability, only: %i[show edit update destroy]
  before_action :set_group, only: %i[new create]
  before_action :set_availabilities, only: %i[new edit create]
  skip_after_action :verify_policy_scoped

  # GET /group_availabilities or /group_availabilities.json
  def index
    @group_availabilities = policy_scope(GroupAvailability).where(group_id: params[:group_id])
  end

  # GET /group_availabilities/1 or /group_availabilities/1.json
  def show
  end

  # GET /group_availabilities/new
  def new
    group_availability = @group.group_availabilities.find_by(user_id: Current.user.id)
    redirect_to edit_group_availability_path(authorize(group_availability)) if group_availability.present?

    @group_availability = authorize(@group.group_availabilities.build(user_id: Current.user.id, group_id: params[:group_id]))
  end

  # GET /group_availabilities/1/edit
  def edit
  end

  # POST /group_availabilities
  def create
    @availability = Availability.find_by!(id: group_availability_params[:availability_id])
    @group_availability = authorize(@group.group_availabilities.new(group_availability_params))

    respond_to do |format|
      if @group_availability.save
        format.html {
          redirect_to @group, success: {message: t("group_availability.create.success",
            availability_name: @availability.name),
                                        options: {highlight: "#{@group_availability.group_name}."}}
        }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /group_availabilities/1
  def update
    respond_to do |format|
      if @group_availability.update(group_availability_params)
        format.html {
          redirect_to @group_availability.group,
            success: {message: t("group_availability.update.success",
              availability_name: @group_availability.availability_name),
                      options: {highlight: "#{@group_availability.group_name}."}}
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_availabilities/1
  def destroy
    group = @group_availability.group
    @group_availability.destroy!

    respond_to do |format|
      format.html {
        redirect_to group, success: {message: t("group_availability.destroy.success",
          group_name: group.name), options: {highlight: "#{@group_availability.group_name}."}}
      }
    end
  end

  private

  def set_group_availability
    @group_availability = authorize(GroupAvailability.find(params[:id]))
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_availabilities
    @availabilities = policy_scope(Availability)
  end

  # Only allow a list of trusted parameters through.
  def group_availability_params
    params.require(:group_availability).permit(:user_id, :group_id, :availability_id)
  end
end
