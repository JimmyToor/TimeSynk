class AvailabilitiesController < ApplicationController
  before_action :set_availability, only: %i[ show edit update destroy ]
  before_action :set_schedules, only: %i[ new edit create ]
  before_action :set_user, only: %i[ create ]

  # GET /availabilities or /availabilities.json
  def index
    @availabilities = policy_scope(Availability)
    authorize(@availabilities)
  end

  # GET /availabilities/1 or /availabilities/1.json
  def show
  end

  # GET /availabilities/new
  def new
    @availability = Availability.new(user: @user)
  end

  # GET /availabilities/1/edit
  def edit
  end

  # POST /availabilities or /availabilities.json
  def create
    @availability = Availability.new(availability_params)
    authorize(@availability)
    respond_to do |format|
      if @availability.save
        format.html { redirect_to availability_url(@availability), notice: "Availability was successfully created." }
        format.json { render :show, status: :created, location: @availability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /availabilities/1 or /availabilities/1.json
  def update
    respond_to do |format|
      if @availability.update(availability_params)
        format.html { redirect_to availability_url(@availability), notice: "Availability was successfully updated." }
        format.json { render :show, status: :ok, location: @availability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /availabilities/1 or /availabilities/1.json
  def destroy # TODO: Disallow destroy on default availability
    @availability.destroy!

    respond_to do |format|
      format.html { redirect_to availabilities_url, notice: "Availability was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
  def set_availability
    @availability = Availability.find(params[:id])
    authorize(@availability)
  end

  def set_user
    @user = User.find(params[:availability][:user_id])
    authorize(@user)
  end

  def set_schedules
    @schedules = policy_scope(Schedule)
    Rails.logger.debug @schedules.inspect

    authorize(@schedules)
  end

    # Only allow a list of trusted parameters through.
  def availability_params
    params.require(:availability).permit(:name,
      :user_id,
      availability_schedules_attributes: [:id, :schedule_id, :_destroy])
  end
end
