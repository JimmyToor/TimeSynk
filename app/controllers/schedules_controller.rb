class SchedulesController < ApplicationController
  before_action :set_schedule, only: %i[ show edit update destroy ]
  skip_after_action :verify_authorized, except: :index
  skip_after_action :verify_policy_scoped, except: :index

  # GET /schedules or /schedules.json
  def index
    @schedules = policy_scope(Schedule)
    authorize(@schedules)
    if params[:start] && params[:end]
      @schedules = @schedules.where("start_date >= ?", params[:start]).each do |schedule|
        schedule if schedule.make_icecube_schedule.occurs_between?(params[:start], params[:end])
        Rails.logger.debug "Schedule: #{schedule.inspect}"
      end
    end
  end

  # GET /schedules/1 or /schedules/1.json
  def show
  end

  # GET /schedules/new
  def new
    @schedule = Schedule.new(start_date: Time.current.utc, duration: 60)
  end

  # GET /schedules/1/edit
  def edit
  end

  # POST /schedules or /schedules.json
  def create
    @schedule = Schedule.new(schedule_params)
    Rails.logger.debug "SchedulesController#create: schedule_params: #{schedule_params.inspect}"
    if @schedule.schedule_pattern.present?
      pattern = @schedule.schedule_pattern
      Rails.logger.debug "SchedulesController#create: pattern: #{pattern.inspect}"
      if pattern[:until].present?
        Rails.logger.debug "SchedulesController#createDuringEndDateChecks: pattern[:until]: #{pattern[:until]}"
        @schedule.end_date = @schedule.schedule_pattern[:until][:time]
      elsif pattern[:count]
        Rails.logger.debug "SchedulesController#createDuringEndDateChecks: pattern[:count]: #{pattern[:count]}"
        @schedule.end_date = @schedule.make_icecube_schedule.last
      end
    else
      Rails.logger.debug "SchedulesController#create: schedule_pattern is empty"
      @schedule.end_date = @schedule.start_date + @schedule.duration.minutes
    end
    Rails.logger.debug "SchedulesController#create: schedule: #{@schedule.inspect}"

    respond_to do |format|
      if @schedule.save
        format.html { redirect_to schedule_url(@schedule), notice: "Schedule was successfully created." }
        format.json { render :show, status: :created, location: @schedule }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT /schedules/1 or /schedules/1.json
  def update
    respond_to do |format|
      if @schedule.update(schedule_params)
        format.html { redirect_to schedule_url(@schedule), notice: "Schedule was successfully updated." }
        format.json { render :show, status: :ok, location: @schedule }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schedules/1 or /schedules/1.json
  def destroy # TODO: Disallow destroy on default schedule
    @schedule.destroy!

    respond_to do |format|
      format.html { redirect_to schedules_url, notice: "Schedule was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def schedule_params
    params.require(:schedule).permit(:name, :user_id, :start_date, :duration, :schedule_pattern).tap do |schedule_params|
      if schedule_params[:start_date].present? && schedule_params[:duration].present?
        start_date = DateTime.parse(schedule_params[:start_date])
        duration = schedule_params[:duration].to_i
        schedule_params[:end_date] = start_date + duration.minutes
      end
    end
  end

end
