class AvailabilitySchedulesController < ApplicationController
  before_action :set_availability, :set_schedules, only: %i[index]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /availability_schedules or /availability_schedules.json
  def index
    @pagy, @schedules = pagy(@schedules)

    @included_schedules = @schedules.select { |schedule| @availability.schedules.include?(schedule) }
    @schedules -= @included_schedules
    respond_to do |format|
      format.html { render :index, locals: {schedules: @schedules, availability: @availability} }
      format.turbo_stream
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def availability_schedule_params
    params.require(:availability_schedule).permit(:availability_id, :schedule_id, :query)
  end

  def set_availability
    @availability = Availability.find(params[:availability_id]) if params[:availability_id].present?
    if @availability.present?
      authorize @availability, :show?, policy_class: AvailabilityPolicy
      if request.format.json?
        render json: @availability.schedules, status: :ok
      end
    else
      @availability = Current.user.availabilities.build(Availability::DEFAULT_PARAMS)
    end
  end

  def set_schedules
    @schedules = params[:query].present? ? policy_scope(Schedule).search(params[:query]) : policy_scope(Schedule)
    authorize @schedules, :show?, policy_class: SchedulePolicy
  end
end
