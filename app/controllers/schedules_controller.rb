class SchedulesController < ApplicationController
  before_action :set_schedule, only: %i[show edit update destroy]
  skip_after_action :verify_authorized, except: :index
  skip_after_action :verify_policy_scoped, except: :index

  # GET /schedules or /schedules.json
  def index
    @schedules = policy_scope(Schedule)
    authorize(@schedules)
    if params[:start] && params[:end]
      @schedules = @schedules.where("start_date >= ?", params[:start]).select do |schedule|
        schedule if schedule.make_icecube_schedule.occurs_between?(params[:start], params[:end])
      end
    end
  end

  # GET /schedules/1 or /schedules/1.json
  def show
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
    Rails.logger.debug "Schedule#createBefore: schedule_params: #{schedule_params.inspect}"
    set_missing_values
    Rails.logger.debug "Schedule#createAfter: schedule_params: #{schedule_params.inspect}"

    respond_to do |format|
      if @schedule.save
        format.html { redirect_to schedule_url(@schedule), notice: "Schedule was successfully created." }
        format.json { render :show, status: :created, location: @schedule }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.update(
              "schedule_form",
              partial: "schedules/form",
              locals: {schedule: Schedule.new(user: Current.user)}
            ),
            turbo_stream.update(
              @schedule,
              partial: "schedules/schedule",
              locals: {schedule: @schedule}
            )
          ]
        }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "schedule_form",
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

  # Only allow a list of trusted parameters through.
  def schedule_params
    params.require(:schedule).permit(:name, :user_id, :start_date, :end_date, :duration, :schedule_pattern,
      availability_schedules_attributes: [:id, :availability_id, :schedule_id, :_destroy]).tap do |schedule_params|
      if schedule_params[:duration].present?
        schedule_params[:duration] = schedule_params[:duration].to_i
      end
    end
  end
end
