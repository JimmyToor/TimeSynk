class AvailabilitySchedulesController < ApplicationController
  before_action :set_availability_schedule, only: %i[show edit update destroy]
  before_action :set_availability, only: %i[index]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /availability_schedules or /availability_schedules.json
  def index
    authorize @availability, :show?, policy_class: AvailabilityPolicy if @availability.present?
    if request.format.json?
      render json: @availability.schedules, status: :ok
      return
    end

    @schedules = params[:query].present? ? policy_scope(Schedule).search(params[:query]) : policy_scope(Schedule)
    authorize @schedules, :show?, policy_class: SchedulePolicy if @schedules.present?
    @pagy, @schedules = pagy(@schedules)
    respond_to do |format|
      format.html { render :index, locals: {pagy: @pagy, schedules: @schedules, availability: @availability} }
      format.turbo_stream
    end
  end

  # GET /availability_schedules/1 or /availability_schedules/1.json
  def show
  end

  # GET /availability_schedules/new
  def new
    @availability_schedule = AvailabilitySchedule.new
  end

  # GET /availability_schedules/1/edit
  def edit
  end

  # POST /availability_schedules or /availability_schedules.json
  def create
    @availability_schedule = AvailabilitySchedule.new(availability_schedule_params)

    respond_to do |format|
      if @availability_schedule.save
        format.html { redirect_to availability_schedule_url(@availability_schedule), notice: "Availability schedule was successfully created." }
        format.json { render :show, status: :created, location: @availability_schedule }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @availability_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /availability_schedules/1 or /availability_schedules/1.json
  def update
    respond_to do |format|
      if @availability_schedule.update(availability_schedule_params)
        format.html { redirect_to availability_schedule_url(@availability_schedule), notice: "Availability schedule was successfully updated." }
        format.json { render :show, status: :ok, location: @availability_schedule }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @availability_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /availability_schedules/1 or /availability_schedules/1.json
  def destroy
    @availability_schedule.destroy!

    respond_to do |format|
      format.html { redirect_to availability_schedules_url, notice: "Availability schedule was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_availability_schedule
    @availability_schedule = AvailabilitySchedule.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def availability_schedule_params
    params.require(:availability_schedule).permit(:availability_id, :schedule_id, :query)
  end

  def set_availability
    @availability = Availability.find(params[:availability_id]) if params[:availability_id].present?
  end
end
