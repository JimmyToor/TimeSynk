class GroupAvailabilitiesController < ApplicationController
  before_action :set_group_availability, only: %i[ show edit update destroy ]

  # GET /group_availabilities or /group_availabilities.json
  def index
    @group_availabilities = GroupAvailability.all
  end

  # GET /group_availabilities/1 or /group_availabilities/1.json
  def show
  end

  # GET /group_availabilities/new
  def new
    @group_availability = GroupAvailability.new
  end

  # GET /group_availabilities/1/edit
  def edit
  end

  # POST /group_availabilities or /group_availabilities.json
  def create
    @group_availability = GroupAvailability.new(group_availability_params)

    respond_to do |format|
      if @group_availability.save
        format.html { redirect_to group_availability_url(@group_availability), notice: "Group availability was successfully created." }
        format.json { render :show, status: :created, location: @group_availability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @group_availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /group_availabilities/1 or /group_availabilities/1.json
  def update
    respond_to do |format|
      if @group_availability.update(group_availability_params)
        format.html { redirect_to group_availability_url(@group_availability), notice: "Group availability was successfully updated." }
        format.json { render :show, status: :ok, location: @group_availability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group_availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_availabilities/1 or /group_availabilities/1.json
  def destroy
    @group_availability.destroy!

    respond_to do |format|
      format.html { redirect_to group_availabilities_url, notice: "Group availability was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group_availability
      @group_availability = GroupAvailability.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_availability_params
      params.require(:group_availability).permit(:user_id, :group_id, :schedule_id)
    end
end
