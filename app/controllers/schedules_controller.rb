class SchedulesController < ApplicationController
  before_action :set_schedule, only: %i[show edit update destroy]
  skip_after_action :verify_authorized, except: :index
  skip_after_action :verify_policy_scoped, except: :index

  # GET /schedules or /schedules.json
  def index
    @schedules = params[:query].present? ? policy_scope(Schedule).search(params[:query]) : policy_scope(Schedule)
    authorize(@schedules)
    @pagy, @schedules = pagy(@schedules)
    if params[:start] && params[:end]
      @schedules = @schedules.where("start_date >= ?", params[:start]).select do |schedule|
        schedule if schedule.make_icecube_schedule.occurs_between?(params[:start], params[:end])
      end
    end
    respond_to do |format|
      format.html { render :index, locals: {schedules: @schedules, pagy: @pagy} }
      format.json { render json: @schedules }
    end
  end

  # GET /schedules/1 or /schedules/1.json
  def show
    respond_to do |format|
      format.html { render :show, locals: {schedule: @schedule} }
      format.json { render json: @schedule }
    end
  end

  # GET /schedules/new
  def new
    @schedule = Schedule.new(start_date: Time.current.utc, end_date: Time.current.utc + 24.hours)
  end

  # GET /schedules/1/edit
  def edit
  end

  # POST /schedules or /schedules.json
  def create
    @schedule = Schedule.new(schedule_params)
    set_missing_values

    respond_to do |format|
      if @schedule.save
        format.html { redirect_to schedule_url(@schedule), notice: "Schedule was successfully created." }
        format.json { render :show, status: :created, location: @schedule }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            helpers.dom_id(@schedule, :form),
            partial: "schedules/form",
            locals: {schedule: @schedule}
          ), status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /schedules/1 or /schedules/1.json
  def update
    set_missing_values
    respond_to do |format|
      if @schedule.update(schedule_params)
        format.html { redirect_to schedule_url(@schedule), notice: "Schedule was successfully updated." }
        format.json { render :show, status: :ok, location: @schedule }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            helpers.dom_id(@schedule, :form),
            partial: "schedules/form",
            locals: {schedule: @schedule}
          ), status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /schedules/1 or /schedules/1.json
  def destroy # TODO: Disallow destroy on default schedule
    @schedule.destroy!

    respond_to do |format|
      format.html { redirect_to schedules_url, notice: "Schedule was successfully destroyed." }
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  private

  def set_missing_values
    set_end_date
    set_duration
  end

  # Sets the end date for the schedule if it is not already present.
  # The end date is calculated based on the schedule pattern, start date, and duration, to be the end of the final occurrence.
  def set_end_date
    return if @schedule.end_date.present?

    if @schedule.schedule_pattern.present?
      pattern = @schedule.schedule_pattern
      @schedule.end_date = if pattern[:until].present?
        pattern[:until][:time]
      elsif @schedule.duration.present?
        if pattern[:count]
          @schedule.make_icecube_schedule.last + @schedule.duration.minutes
        else
          @schedule.start_date + @schedule.duration.minutes
        end
      end
    elsif @schedule.duration.present? && @schedule.start_date.present?
      @schedule.end_date = @schedule.start_date + @schedule.duration.minutes
    end
  end

  def set_duration
    if @schedule.start_date.present? && @schedule.end_date.present? && (@schedule.duration.nil? || !@schedule.duration.present?)
      @schedule.duration = (@schedule.end_date - @schedule.start_date).to_i
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  # `duration` is length of time in seconds
  def schedule_params
    params.require(:schedule).permit(:name, :user_id, :start_date, :end_date, :duration, :frequency, :description, :schedule_pattern, :query,
      availability_schedules_attributes: [:id, :availability_id, :schedule_id, :_destroy])
  end
end
