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
    @schedule = Schedule.new(start_date: Time.current.utc, duration: 60)
  end

  # GET /schedules/1/edit
  def edit
  end

  # POST /schedules or /schedules.json
  def create
    @schedule = Schedule.new(schedule_params)
    fill_missing_params

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
    fill_missing_params
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

  def fill_missing_params
    set_end_date
    set_duration
  end

  def set_end_date
    if @schedule.schedule_pattern.present? && @schedule.duration.present? && !@schedule.end_date.present?
      pattern = @schedule.schedule_pattern
      @schedule.end_date = if pattern[:until].present?
        pattern[:until][:time]
      elsif pattern[:count]
        @schedule.make_icecube_schedule.last + schedule_params[:duration].minutes
      else
        @schedule.start_date + @schedule.duration.minutes
      end
    else
      @schedule.end_date = @schedule.start_date + @schedule.duration.minutes
    end
  end

  def set_duration
    if @schedule.start_date.present? && @schedule.end_date.present? && @schedule.duration.nil?
      @schedule.duration = ((@schedule.end_date - @schedule.start_date) * 24 * 60).to_i
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
      elsif schedule_params[:end_date].present?
        schedule_params[:duration] = ((schedule_params[:end_date].to_datetime - schedule_params[:start_date].to_datetime) * 24 * 60).to_i
      end
    end
  end
end
