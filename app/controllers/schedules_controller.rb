class SchedulesController < ApplicationController
  include DurationSaturator
  before_action -> { populate_duration_param([:schedule]) }, only: %i[create update]
  before_action :calc_end_param, only: %i[create update]
  before_action :set_availability, only: %i[index]
  before_action :set_schedule, only: %i[show edit update destroy]
  skip_after_action :verify_authorized, only: %i[show new create]
  skip_after_action :verify_policy_scoped, only: %i[show new edit create update destroy]

  # GET /schedules or /schedules.json
  def index
    @schedules = params[:query].present? ? policy_scope(Schedule).search(params[:query]) : policy_scope(Schedule)
    authorize(@schedules)
    @pagy, @schedules = pagy(@schedules)
    separate_included if params[:separate_included] && @availability.present?

    respond_to do |format|
      format.html { render :index, locals: {schedules: @schedules} }
      format.turbo_stream
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
    @schedule = Schedule.new_default(user_id: Current.user.id)
  end

  # GET /schedules/1/edit
  def edit
  end

  # POST /schedules or /schedules.json
  def create
    @schedule = Schedule.new(schedule_params)
    @schedule.set_end_time(schedule_params[:duration]) if @schedule.duration.nil?

    respond_to do |format|
      if @schedule.save
        format.html { redirect_to schedule_url(@schedule), notice: "Schedule was successfully created." }
        format.json { render :show, status: :created, location: @schedule }
        format.turbo_stream
      else
        flash.now[:alert] = {message: I18n.t("schedule.create.error"),
                                      options: {list_items: @schedule.errors.full_messages}}
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /schedules/1 or /schedules/1.json
  def update
    @schedule.set_end_time(schedule_params[:duration])
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
  def destroy
    @schedule.destroy!

    respond_to do |format|
      format.html { redirect_to schedules_url, notice: "Schedule was successfully destroyed." }
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  private

  def set_availability
    @availability = Availability.find(params[:availability_id]) if params[:availability_id].present?
  end

  def set_schedule
    @schedule = authorize(Schedule.find(params[:id]))
  end

  # `duration` is length of time in seconds
  def schedule_params
    params.require(:schedule).permit(:name, :user_id, :start_time, :end_time, :availability_id, :duration, :duration_days, :duration_hours, :duration_minutes, :frequency, :description, :schedule_pattern, :query,
      availability_schedules_attributes: [:id, :availability_id, :schedule_id, :_destroy])
  end

  def parts_to_duration
    if params[:schedule][:duration_days].present? && params[:schedule][:duration_hours].present? && params[:schedule][:duration_minutes].present? && !params[:schedule][:duration].present?
      params[:schedule][:duration] = Schedule.parts_to_duration(days: params[:schedule][:duration_days], hours: params[:schedule][:duration_hours], minutes: params[:schedule][:duration_minutes])
    end
  end

  def calc_end_param
    unless params[:schedule][:end_time].present?
      params[:schedule][:end_time] = DateTime.parse(params[:schedule][:start_time]) + params[:schedule][:duration].to_i.seconds
    end
    params[:schedule] = params[:schedule].except(:duration_days, :duration_hours, :duration_minutes)
  end

  def separate_included
    included_schedule_ids = @availability.schedule_ids.to_set
    @included_schedules, @schedules = @schedules.partition { |schedule| included_schedule_ids.include?(schedule.id) }
  end
end
